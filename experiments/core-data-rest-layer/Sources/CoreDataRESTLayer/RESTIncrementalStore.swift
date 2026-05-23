import CoreData
import Foundation

public enum RESTIncrementalStoreError: Error, CustomStringConvertible {
    case missingBaseURL
    case invalidReferenceObject(Any)
    case unsupportedRequest(NSPersistentStoreRequestType)
    case unsupportedEntity(String?)
    case unsupportedRelationship(String)
    case invalidResponse
    case httpStatus(Int, String)

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
        }
    }
}

public final class RESTCoreDataStack {
    public let coordinator: NSPersistentStoreCoordinator
    public let context: NSManagedObjectContext

    public init(baseURL: URL) throws {
        RESTIncrementalStore.registerStoreClass()

        coordinator = NSPersistentStoreCoordinator(managedObjectModel: CoreDataStack.makeModel())
        try coordinator.addPersistentStore(
            ofType: RESTIncrementalStore.storeType,
            configurationName: nil,
            at: URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("CoreDataRESTLayer-\(UUID().uuidString).rest"),
            options: [RESTIncrementalStore.baseURLOptionKey: baseURL.absoluteString]
        )

        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
    }
}

@objc(RESTIncrementalStore)
public final class RESTIncrementalStore: NSIncrementalStore {
    public static let storeType = "RESTIncrementalStore"
    public static let baseURLOptionKey = "CoreDataRESTLayer.RESTIncrementalStore.baseURL"

    private var client: BlockingRESTClient?
    private let lock = NSLock()
    private var projectCache: [UUID: RemoteProject] = [:]
    private var taskCache: [UUID: RemoteTask] = [:]
    private var taskIDsByProjectID: [UUID: [UUID]] = [:]

    public static func registerStoreClass() {
        NSPersistentStoreCoordinator.registerStoreClass(Self.self, forStoreType: storeType)
    }

    public override func loadMetadata() throws {
        guard let baseURLString = options?[Self.baseURLOptionKey] as? String,
              let baseURL = URL(string: baseURLString) else {
            throw RESTIncrementalStoreError.missingBaseURL
        }

        client = BlockingRESTClient(baseURL: baseURL)
        metadata = [
            NSStoreTypeKey: Self.storeType,
            NSStoreUUIDKey: UUID().uuidString,
            "RESTBaseURL": baseURL.absoluteString,
            "LocalModelVersion": CoreDataStack.localModelVersion.rawValue,
            "WritableAPIVersion": APIModelVersionMapping.current.writableAPIVersion.rawValue
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
        default:
            throw RESTIncrementalStoreError.unsupportedEntity(fetchRequest.entity?.name)
        }
    }

    public override func newValuesForObject(
        with objectID: NSManagedObjectID,
        with context: NSManagedObjectContext?
    ) throws -> NSIncrementalStoreNode {
        let id = try uuidReference(from: objectID)

        switch objectID.entity.name {
        case "CDProject":
            let project = try cachedProject(id: id)
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
            let task = try cachedTask(id: id)
            let values: [String: Any] = [
                "id": task.id,
                "title": task.title,
                "status": task.status,
                "updatedAt": task.updatedAt,
                "version": Int64(task.version),
                "isDirty": false
            ]
            return NSIncrementalStoreNode(
                objectID: objectID,
                withValues: values,
                version: UInt64(task.version)
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
            let tasks = try fetchRemoteTasks(projectID: projectID)
            let ids = tasks.map { task in
                self.newObjectID(for: entity(named: "CDTask"), referenceObject: task.id.uuidString)
            }
            return NSSet(array: ids)
        case ("CDTask", "project"):
            let taskID = try uuidReference(from: objectID)
            let task = try cachedTask(id: taskID)
            return newObjectID(for: entity(named: "CDProject"), referenceObject: task.projectId.uuidString)
        default:
            throw RESTIncrementalStoreError.unsupportedRelationship(relationship.name)
        }
    }

    public override func obtainPermanentIDs(for array: [NSManagedObject]) throws -> [NSManagedObjectID] {
        try array.map { object in
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
            let remote = try requireClient().patchTask(
                id: id,
                title: object.value(forKey: "title") as? String ?? "",
                status: object.value(forKey: "status") as? String ?? "",
                version: Int(object.value(forKey: "version") as? Int64 ?? 0)
            )
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

    private func fetchRemoteTasks(projectID: UUID) throws -> [RemoteTask] {
        let tasks = try requireClient().fetchTasks(projectID: projectID)
        lock.withLock {
            taskIDsByProjectID[projectID] = tasks.map(\.id)
            for task in tasks {
                taskCache[task.id] = task
            }
        }
        return tasks
    }

    private func fetchRemoteTasksForAllProjects() throws -> [RemoteTask] {
        try fetchRemoteProjects().flatMap { project in
            try fetchRemoteTasks(projectID: project.id)
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

    private func entity(named name: String) -> NSEntityDescription {
        persistentStoreCoordinator!.managedObjectModel.entitiesByName[name]!
    }

    private func requireClient() throws -> BlockingRESTClient {
        guard let client else {
            throw RESTIncrementalStoreError.missingBaseURL
        }
        return client
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

    func fetchTasks(projectID: UUID) throws -> [RemoteTask] {
        try send(path: "/projects/\(projectID.uuidString)/tasks", responseType: [RemoteTask].self)
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
        guard (200..<300).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw RESTIncrementalStoreError.httpStatus(httpResponse.statusCode, body)
        }
        return try decoder.decode(Response.self, from: data)
    }
}

private extension NSLock {
    func withLock<Value>(_ body: () throws -> Value) rethrows -> Value {
        lock()
        defer { unlock() }
        return try body()
    }
}
