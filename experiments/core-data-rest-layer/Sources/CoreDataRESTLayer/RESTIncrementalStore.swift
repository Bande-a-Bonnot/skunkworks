import CoreData
import Foundation

public enum RESTIncrementalStoreError: Error, CustomStringConvertible, CustomNSError {
    case missingBaseURL
    case invalidReferenceObject(Any)
    case unsupportedRequest(NSPersistentStoreRequestType)
    case unsupportedEntity(String?)
    case unsupportedRelationship(String)
    case invalidResponse
    case httpStatus(Int, String)
    case conflict(remote: RemoteTask)

    public static var errorDomain: String {
        "CoreDataRESTLayer.RESTIncrementalStoreError"
    }

    public var errorCode: Int {
        switch self {
        case .missingBaseURL: return 1
        case .invalidReferenceObject: return 2
        case .unsupportedRequest: return 3
        case .unsupportedEntity: return 4
        case .unsupportedRelationship: return 5
        case .invalidResponse: return 6
        case .httpStatus: return 7
        case .conflict: return 8
        }
    }

    public var errorUserInfo: [String: Any] {
        var userInfo: [String: Any] = [NSLocalizedDescriptionKey: description]
        switch self {
        case let .httpStatus(status, body):
            userInfo["HTTPStatusCode"] = status
            userInfo["ResponseBody"] = body
        case let .conflict(remote):
            userInfo["RemoteTaskID"] = remote.id.uuidString
            userInfo["RemoteVersion"] = remote.version
            userInfo["RemoteTitle"] = remote.title
            userInfo["RemoteStatus"] = remote.status
        case let .invalidReferenceObject(reference):
            userInfo["ReferenceObject"] = String(describing: reference)
        case let .unsupportedRequest(type):
            userInfo["PersistentStoreRequestType"] = type.rawValue
        case let .unsupportedEntity(entity):
            if let entity {
                userInfo["EntityName"] = entity
            }
        case let .unsupportedRelationship(relationship):
            userInfo["RelationshipName"] = relationship
        case .missingBaseURL, .invalidResponse:
            break
        }
        return userInfo
    }

    public var description: String {
        switch self {
        case .missingBaseURL:
            return "REST incremental store requires a base URL option"
        case let .invalidReferenceObject(reference):
            return "Invalid reference object: \(reference)"
        case let .unsupportedRequest(type):
            return "Unsupported persistent store request type: \(type.rawValue)"
        case let .unsupportedEntity(entity):
            return "Unsupported entity: \(entity ?? "nil")"
        case let .unsupportedRelationship(name):
            return "Unsupported relationship: \(name)"
        case .invalidResponse:
            return "Invalid HTTP response"
        case let .httpStatus(status, body):
            return "HTTP \(status): \(body)"
        case let .conflict(remote):
            return "Conflict with remote task \(remote.id) at version \(remote.version)"
        }
    }
}

public final class RESTCoreDataStack {
    public let coordinator: NSPersistentStoreCoordinator
    public let context: NSManagedObjectContext

    public init(baseURL: URL, taskPagination: TaskPaginationStrategy = .none) throws {
        RESTIncrementalStore.registerStoreClass()

        coordinator = NSPersistentStoreCoordinator(managedObjectModel: CoreDataStack.makeModel())
        try coordinator.addPersistentStore(
            ofType: RESTIncrementalStore.storeType,
            configurationName: nil,
            at: URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("CoreDataRESTLayer-\(UUID().uuidString).rest"),
            options: RESTIncrementalStore.options(baseURL: baseURL, taskPagination: taskPagination)
        )

        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
    }

    public func makeBackgroundContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        return context
    }

    public func loadTaskDetails(for task: CDTask) throws {
        guard let store = coordinator.persistentStores.first as? RESTIncrementalStore else {
            throw RESTIncrementalStoreError.unsupportedEntity(task.entity.name)
        }
        try store.loadTaskDetails(for: task.objectID)
        task.managedObjectContext?.refresh(task, mergeChanges: false)
    }
}

@objc(RESTIncrementalStore)
public final class RESTIncrementalStore: NSIncrementalStore {
    public static let storeType = "RESTIncrementalStore"
    public static let baseURLOptionKey = "CoreDataRESTLayer.RESTIncrementalStore.baseURL"
    public static let taskPaginationModeOptionKey = "CoreDataRESTLayer.RESTIncrementalStore.taskPaginationMode"
    public static let taskPaginationLimitOptionKey = "CoreDataRESTLayer.RESTIncrementalStore.taskPaginationLimit"

    private var client: BlockingRESTClient?
    private var taskPagination: TaskPaginationStrategy = .none
    private let lock = NSLock()
    private var projectCache: [UUID: RemoteProject] = [:]
    private var taskCache: [UUID: RemoteTask] = [:]
    private var taskIDsByProjectID: [UUID: [UUID]] = [:]
    private var relationshipStateCache: [String: RemoteRelationshipStateSnapshot] = [:]

    public static func registerStoreClass() {
        NSPersistentStoreCoordinator.registerStoreClass(Self.self, forStoreType: storeType)
    }

    public static func options(baseURL: URL, taskPagination: TaskPaginationStrategy = .none) -> [AnyHashable: Any] {
        var options: [AnyHashable: Any] = [baseURLOptionKey: baseURL.absoluteString]
        switch taskPagination {
        case .none:
            options[taskPaginationModeOptionKey] = "none"
        case let .cursor(limit):
            options[taskPaginationModeOptionKey] = "cursor"
            options[taskPaginationLimitOptionKey] = limit
        case let .offset(limit):
            options[taskPaginationModeOptionKey] = "offset"
            options[taskPaginationLimitOptionKey] = limit
        case let .numberedPages(perPage):
            options[taskPaginationModeOptionKey] = "numberedPages"
            options[taskPaginationLimitOptionKey] = perPage
        }
        return options
    }

    public override func loadMetadata() throws {
        guard let baseURLString = options?[Self.baseURLOptionKey] as? String,
              let baseURL = URL(string: baseURLString) else {
            throw RESTIncrementalStoreError.missingBaseURL
        }

        client = BlockingRESTClient(baseURL: baseURL)
        taskPagination = Self.paginationStrategy(from: options)
        metadata = [
            NSStoreTypeKey: Self.storeType,
            NSStoreUUIDKey: UUID().uuidString,
            "RESTBaseURL": baseURL.absoluteString,
            "LocalModelVersion": CoreDataStack.localModelVersion.rawValue,
            "WritableAPIVersion": APIModelVersionMapping.current.writableAPIVersion.rawValue,
            "TaskPaginationStrategy": String(describing: taskPagination)
        ]
    }

    public override func execute(
        _ request: NSPersistentStoreRequest,
        with context: NSManagedObjectContext?
    ) throws -> Any {
        if request.requestType == .saveRequestType,
           let saveRequest = request as? NSSaveChangesRequest {
            try executeSave(saveRequest)
            return []
        }

        guard request.requestType == .fetchRequestType,
              let fetchRequest = request as? NSFetchRequest<NSFetchRequestResult> else {
            throw RESTIncrementalStoreError.unsupportedRequest(request.requestType)
        }

        guard let context else {
            throw RESTIncrementalStoreError.invalidResponse
        }

        switch fetchRequest.entity?.name {
        case "CDProject":
            let projects = try fetchRemoteProjects()
            return projects.map { project in
                context.object(with: newObjectID(for: entity(named: "CDProject"), referenceObject: project.id.uuidString))
            }
        case "CDTask":
            let tasks = try fetchRemoteTasksForAllProjects()
            return tasks.map { task in
                context.object(with: newObjectID(for: entity(named: "CDTask"), referenceObject: task.id.uuidString))
            }
        case "CDRemoteRelationshipState":
            let states = lock.withLock { Array(relationshipStateCache.values) }
            return states.map { state in
                context.object(with: newObjectID(for: entity(named: "CDRemoteRelationshipState"), referenceObject: state.id))
            }
        default:
            throw RESTIncrementalStoreError.unsupportedEntity(fetchRequest.entity?.name)
        }
    }

    public override func newValuesForObject(
        with objectID: NSManagedObjectID,
        with context: NSManagedObjectContext?
    ) throws -> NSIncrementalStoreNode {
        switch objectID.entity.name {
        case "CDProject":
            let project = try cachedProject(id: try uuidReference(from: objectID))
            return NSIncrementalStoreNode(
                objectID: objectID,
                withValues: [
                    "id": project.id,
                    "name": project.name,
                    "updatedAt": project.updatedAt,
                    "version": Int64(project.version)
                ],
                version: UInt64(project.version)
            )
        case "CDTask":
            let task = try cachedTask(id: try uuidReference(from: objectID))
            let values: [String: Any] = [
                "id": task.id,
                "title": task.title,
                "status": task.status,
                "loadedFields": task.loadedFieldsDescription,
                "updatedAt": task.updatedAt,
                "version": Int64(task.version),
                "isDirty": false
            ]
            var loadedValues = values
            if task.isDetailLoaded, let notes = task.notes {
                loadedValues["notes"] = notes
            }
            return NSIncrementalStoreNode(
                objectID: objectID,
                withValues: loadedValues,
                version: UInt64(task.version)
            )
        case "CDRemoteRelationshipState":
            let state = try cachedRelationshipState(reference: try stringReference(from: objectID))
            return NSIncrementalStoreNode(
                objectID: objectID,
                withValues: state.values,
                version: UInt64(state.version)
            )
        default:
            throw RESTIncrementalStoreError.unsupportedEntity(objectID.entity.name)
        }
    }

    public override func newValue(
        forRelationship relationship: NSRelationshipDescription,
        forObjectWith objectID: NSManagedObjectID,
        with context: NSManagedObjectContext?
    ) throws -> Any {
        switch (objectID.entity.name, relationship.name) {
        case ("CDProject", "tasks"):
            let projectID = try uuidReference(from: objectID)
            do {
                let tasks = try fetchRemoteTasks(projectID: projectID, pagination: taskPagination)
                updateRelationshipState(
                    ownerEntityName: "CDProject",
                    ownerRemoteID: projectID.uuidString,
                    relationshipName: "tasks",
                    fetchedCount: tasks.count,
                    isComplete: true,
                    lastError: nil
                )
                let ids = tasks.map { task in
                    self.newObjectID(for: entity(named: "CDTask"), referenceObject: task.id.uuidString)
                }
                return NSSet(array: ids)
            } catch {
                updateRelationshipState(
                    ownerEntityName: "CDProject",
                    ownerRemoteID: projectID.uuidString,
                    relationshipName: "tasks",
                    fetchedCount: 0,
                    isComplete: false,
                    lastError: String(describing: error)
                )
                throw error
            }
        case ("CDTask", "project"):
            let taskID = try uuidReference(from: objectID)
            let task = try cachedTask(id: taskID)
            return newObjectID(for: entity(named: "CDProject"), referenceObject: task.projectId.uuidString)
        default:
            throw RESTIncrementalStoreError.unsupportedRelationship(relationship.name)
        }
    }

    public func loadTaskDetails(for objectID: NSManagedObjectID) throws {
        guard objectID.entity.name == "CDTask" else {
            throw RESTIncrementalStoreError.unsupportedEntity(objectID.entity.name)
        }
        _ = try fetchRemoteTaskDetail(id: try uuidReference(from: objectID))
    }

    public override func obtainPermanentIDs(for array: [NSManagedObject]) throws -> [NSManagedObjectID] {
        try array.map { object in
            if object.entity.name == "CDRemoteRelationshipState",
               let id = object.value(forKey: "id") as? String {
                return newObjectID(for: object.entity, referenceObject: id)
            }
            guard let id = object.value(forKey: "id") as? UUID else {
                throw RESTIncrementalStoreError.invalidReferenceObject(object)
            }
            return newObjectID(for: object.entity, referenceObject: id.uuidString)
        }
    }

    private func executeSave(_ saveRequest: NSSaveChangesRequest) throws {
        for object in saveRequest.updatedObjects ?? [] where object.entity.name == "CDTask" {
            guard let id = object.value(forKey: "id") as? UUID else {
                throw RESTIncrementalStoreError.invalidReferenceObject(object)
            }
            let remote: RemoteTask
            do {
                remote = try requireClient().patchTask(
                    id: id,
                    title: object.value(forKey: "title") as? String ?? "",
                    status: object.value(forKey: "status") as? String ?? "",
                    version: Int(object.value(forKey: "version") as? Int64 ?? 0)
                )
            } catch RESTIncrementalStoreError.conflict(let remote) {
                object.setValue(true, forKey: "isDirty")
                object.setValue(
                    "Conflict: remote version \(remote.version) has title '\(remote.title)' and status '\(remote.status)'",
                    forKey: "lastSyncError"
                )
                object.setValue("remoteVersion=\(remote.version)", forKey: "conflictState")
                throw RESTIncrementalStoreError.conflict(remote: remote)
            }
            lock.withLock {
                taskCache[remote.id] = remote
            }
            object.setValue(remote.updatedAt, forKey: "updatedAt")
            object.setValue(Int64(remote.version), forKey: "version")
            object.setValue(false, forKey: "isDirty")
            object.setValue(nil, forKey: "lastSyncError")
            object.setValue(nil, forKey: "conflictState")
        }
    }

    private func fetchRemoteProjects() throws -> [RemoteProject] {
        let projects = try requireClient().fetchProjects()
        lock.withLock {
            for project in projects {
                projectCache[project.id] = project
            }
        }
        return projects
    }

    private func fetchRemoteTasks(projectID: UUID, pagination: TaskPaginationStrategy = .none) throws -> [RemoteTask] {
        let tasks = try requireClient().fetchTasks(projectID: projectID, pagination: pagination)
        lock.withLock {
            taskIDsByProjectID[projectID] = tasks.map(\.id)
            for task in tasks {
                taskCache[task.id] = task
            }
        }
        return tasks
    }

    private func fetchRemoteTaskDetail(id: UUID) throws -> RemoteTask {
        let task = try requireClient().fetchTask(id: id)
        lock.withLock {
            taskCache[task.id] = task
        }
        return task
    }

    private func fetchRemoteTasksForAllProjects() throws -> [RemoteTask] {
        try fetchRemoteProjects().flatMap { project in
            try fetchRemoteTasks(projectID: project.id, pagination: taskPagination)
        }
    }

    private func cachedProject(id: UUID) throws -> RemoteProject {
        if let project = lock.withLock({ projectCache[id] }) {
            return project
        }
        return try fetchRemoteProjects().first { $0.id == id } ?? {
            throw RESTIncrementalStoreError.invalidReferenceObject(id)
        }()
    }

    private func cachedTask(id: UUID) throws -> RemoteTask {
        if let task = lock.withLock({ taskCache[id] }) {
            return task
        }
        return try fetchRemoteTasksForAllProjects().first { $0.id == id } ?? {
            throw RESTIncrementalStoreError.invalidReferenceObject(id)
        }()
    }

    private func cachedRelationshipState(reference: String) throws -> RemoteRelationshipStateSnapshot {
        if let state = lock.withLock({ relationshipStateCache[reference] }) {
            return state
        }
        throw RESTIncrementalStoreError.invalidReferenceObject(reference)
    }

    private func updateRelationshipState(
        ownerEntityName: String,
        ownerRemoteID: String,
        relationshipName: String,
        fetchedCount: Int,
        isComplete: Bool,
        lastError: String?
    ) {
        let id = Self.relationshipStateID(
            ownerEntityName: ownerEntityName,
            ownerRemoteID: ownerRemoteID,
            relationshipName: relationshipName
        )
        let state = RemoteRelationshipStateSnapshot(
            id: id,
            ownerEntityName: ownerEntityName,
            ownerRemoteID: ownerRemoteID,
            relationshipName: relationshipName,
            paginationMode: Self.paginationDescription(taskPagination),
            isComplete: isComplete,
            fetchedCount: fetchedCount,
            totalCount: isComplete ? fetchedCount : 0,
            nextCursor: nil,
            lastLoadedAt: isComplete ? Date() : nil,
            lastError: lastError,
            version: (lock.withLock { relationshipStateCache[id]?.version } ?? 0) + 1
        )
        lock.withLock {
            relationshipStateCache[id] = state
        }
    }

    private func uuidReference(from objectID: NSManagedObjectID) throws -> UUID {
        let reference = referenceObject(for: objectID)
        if let uuid = reference as? UUID {
            return uuid
        }
        if let string = reference as? String, let uuid = UUID(uuidString: string) {
            return uuid
        }
        throw RESTIncrementalStoreError.invalidReferenceObject(reference as Any)
    }

    private func stringReference(from objectID: NSManagedObjectID) throws -> String {
        let reference = referenceObject(for: objectID)
        if let string = reference as? String {
            return string
        }
        throw RESTIncrementalStoreError.invalidReferenceObject(reference as Any)
    }

    private func entity(named name: String) -> NSEntityDescription {
        persistentStoreCoordinator!.managedObjectModel.entitiesByName[name]!
    }

    private func requireClient() throws -> BlockingRESTClient {
        guard let client else {
            throw RESTIncrementalStoreError.missingBaseURL
        }
        return client
    }

    private static func paginationStrategy(from options: [AnyHashable: Any]?) -> TaskPaginationStrategy {
        let mode = options?[taskPaginationModeOptionKey] as? String ?? "none"
        let limit = options?[taskPaginationLimitOptionKey] as? Int ?? 0
        switch mode {
        case "cursor" where limit > 0:
            return .cursor(limit: limit)
        case "offset" where limit > 0:
            return .offset(limit: limit)
        case "numberedPages" where limit > 0:
            return .numberedPages(perPage: limit)
        default:
            return .none
        }
    }

    private static func paginationDescription(_ pagination: TaskPaginationStrategy) -> String {
        switch pagination {
        case .none:
            return "none"
        case let .cursor(limit):
            return "cursor(limit:\(limit))"
        case let .offset(limit):
            return "offset(limit:\(limit))"
        case let .numberedPages(perPage):
            return "numberedPages(perPage:\(perPage))"
        }
    }

    private static func relationshipStateID(
        ownerEntityName: String,
        ownerRemoteID: String,
        relationshipName: String
    ) -> String {
        "\(ownerEntityName):\(ownerRemoteID):\(relationshipName)"
    }
}

private extension RemoteTask {
    var loadedFieldsDescription: String {
        isDetailLoaded ? "summary,notes" : "summary"
    }
}

private struct RemoteRelationshipStateSnapshot {
    var id: String
    var ownerEntityName: String
    var ownerRemoteID: String
    var relationshipName: String
    var paginationMode: String
    var isComplete: Bool
    var fetchedCount: Int
    var totalCount: Int
    var nextCursor: String?
    var lastLoadedAt: Date?
    var lastError: String?
    var version: Int

    var values: [String: Any] {
        var values: [String: Any] = [
            "id": id,
            "ownerEntityName": ownerEntityName,
            "ownerRemoteID": ownerRemoteID,
            "relationshipName": relationshipName,
            "paginationMode": paginationMode,
            "isComplete": isComplete,
            "fetchedCount": Int64(fetchedCount),
            "totalCount": Int64(totalCount)
        ]
        if let nextCursor {
            values["nextCursor"] = nextCursor
        }
        if let lastLoadedAt {
            values["lastLoadedAt"] = lastLoadedAt
        }
        if let lastError {
            values["lastError"] = lastError
        }
        return values
    }
}

private final class BlockingRESTClient {
    private let baseURL: URL
    private let decoder = JSONCoding.makeDecoder()

    init(baseURL: URL) {
        self.baseURL = baseURL
    }

    func fetchProjects() throws -> [RemoteProject] {
        try send(path: "/projects", responseType: [RemoteProject].self)
    }

    func fetchTask(id: UUID) throws -> RemoteTask {
        try send(path: "/tasks/\(id.uuidString)", responseType: RemoteTask.self)
    }

    func fetchTasks(projectID: UUID, pagination: TaskPaginationStrategy = .none) throws -> [RemoteTask] {
        switch pagination {
        case .none:
            return try send(path: "/projects/\(projectID.uuidString)/tasks", responseType: [RemoteTask].self)
        case let .cursor(limit):
            var allTasks: [RemoteTask] = []
            var cursor: String?
            repeat {
                let page = try fetchTaskCursorPage(projectID: projectID, limit: limit, cursor: cursor)
                allTasks.append(contentsOf: page.items)
                cursor = page.nextCursor
            } while cursor != nil
            return allTasks
        case let .offset(limit):
            var allTasks: [RemoteTask] = []
            var offset = 0
            while true {
                let page = try fetchTaskOffsetPage(projectID: projectID, limit: limit, offset: offset)
                allTasks.append(contentsOf: page)
                guard page.count == limit else { break }
                offset += page.count
            }
            return allTasks
        case let .numberedPages(perPage):
            var allTasks: [RemoteTask] = []
            var pageIndex = 1
            while true {
                let page = try fetchTaskNumberedPage(projectID: projectID, page: pageIndex, perPage: perPage)
                allTasks.append(contentsOf: page.items)
                if let totalPages = page.totalPages {
                    guard page.page < totalPages else { break }
                } else {
                    guard page.items.count == perPage else { break }
                }
                pageIndex += 1
            }
            return allTasks
        }
    }

    func fetchTaskCursorPage(projectID: UUID, limit: Int, cursor: String?) throws -> CursorPage<RemoteTask> {
        var components = URLComponents()
        components.path = "/projects/\(projectID.uuidString)/tasks"
        components.queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        if let cursor {
            components.queryItems?.append(URLQueryItem(name: "cursor", value: cursor))
        }
        guard let path = components.string else {
            throw RESTIncrementalStoreError.invalidResponse
        }
        return try send(path: path, responseType: CursorPage<RemoteTask>.self)
    }

    func fetchTaskOffsetPage(projectID: UUID, limit: Int, offset: Int) throws -> [RemoteTask] {
        var components = URLComponents()
        components.path = "/projects/\(projectID.uuidString)/tasks"
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        guard let path = components.string else {
            throw RESTIncrementalStoreError.invalidResponse
        }
        return try send(path: path, responseType: [RemoteTask].self)
    }

    func fetchTaskNumberedPage(projectID: UUID, page: Int, perPage: Int) throws -> NumberedPage<RemoteTask> {
        var components = URLComponents()
        components.path = "/projects/\(projectID.uuidString)/tasks"
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "perPage", value: String(perPage))
        ]
        guard let path = components.string else {
            throw RESTIncrementalStoreError.invalidResponse
        }
        return try send(path: path, responseType: NumberedPage<RemoteTask>.self)
    }

    func patchTask(id: UUID, title: String, status: String, version: Int) throws -> RemoteTask {
        try send(
            path: "/tasks/\(id.uuidString)",
            method: "PATCH",
            requestBody: TaskPatch(title: title, status: status, version: version),
            responseType: RemoteTask.self
        )
    }

    private func send<Response: Decodable>(path: String, responseType: Response.Type) throws -> Response {
        try send(path: path, method: "GET", requestBody: Optional<TaskPatch>.none, responseType: responseType)
    }

    private func send<RequestBody: Encodable, Response: Decodable>(
        path: String,
        method: String,
        requestBody: RequestBody?,
        responseType: Response.Type
    ) throws -> Response {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw RESTIncrementalStoreError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(APIModelVersionMapping.current.writableAPIVersion.rawValue, forHTTPHeaderField: "X-API-Version")
        request.setValue(String(CoreDataStack.localModelVersion.rawValue), forHTTPHeaderField: "X-Local-Model-Version")
        if let requestBody {
            request.httpBody = try JSONCoding.makeEncoder().encode(requestBody)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<(Data, URLResponse), Error>!
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                result = .failure(error)
            } else if let data, let response {
                result = .success((data, response))
            } else {
                result = .failure(RESTIncrementalStoreError.invalidResponse)
            }
            semaphore.signal()
        }.resume()
        semaphore.wait()

        let (data, response) = try result.get()
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RESTIncrementalStoreError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200..<300:
            return try decoder.decode(Response.self, from: data)
        case 409:
            if let conflict = try? decoder.decode(StoreConflictResponse.self, from: data) {
                throw RESTIncrementalStoreError.conflict(remote: conflict.current)
            }
            fallthrough
        default:
            let body = String(data: data, encoding: .utf8) ?? ""
            throw RESTIncrementalStoreError.httpStatus(httpResponse.statusCode, body)
        }
    }
}

private struct StoreConflictResponse: Decodable {
    var error: String
    var current: RemoteTask
}

private extension NSLock {
    func withLock<Value>(_ body: () throws -> Value) rethrows -> Value {
        lock()
        defer { unlock() }
        return try body()
    }
}
