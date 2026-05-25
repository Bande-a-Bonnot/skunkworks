import CoreData
import Foundation

@objc(CDProject)
public class CDProject: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var updatedAt: Date
    @NSManaged public var version: Int64
    @NSManaged public var tasks: Set<CDTask>
}

@objc(CDTask)
public class CDTask: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var status: String
    @NSManaged public var notes: String?
    @NSManaged public var loadedFields: String
    @NSManaged public var updatedAt: Date
    @NSManaged public var version: Int64
    @NSManaged public var isDirty: Bool
    @NSManaged public var lastSyncError: String?
    @NSManaged public var conflictState: String?
    @NSManaged public var project: CDProject?
}

@objc(CDPendingTaskChange)
public class CDPendingTaskChange: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var taskID: UUID
    @NSManaged public var baseVersion: Int64
    @NSManaged public var title: String
    @NSManaged public var status: String
    @NSManaged public var changedFields: String
    @NSManaged public var state: String
    @NSManaged public var attemptCount: Int64
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var lastAttemptedAt: Date?
    @NSManaged public var lastError: String?
    @NSManaged public var conflictRemoteVersion: Int64
    @NSManaged public var conflictRemoteTitle: String?
    @NSManaged public var conflictRemoteStatus: String?
}

@objc(CDRemoteRelationshipState)
public class CDRemoteRelationshipState: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var ownerEntityName: String
    @NSManaged public var ownerRemoteID: String
    @NSManaged public var relationshipName: String
    @NSManaged public var paginationMode: String
    @NSManaged public var isComplete: Bool
    @NSManaged public var fetchedCount: Int64
    @NSManaged public var totalCount: Int64
    @NSManaged public var nextCursor: String?
    @NSManaged public var lastLoadedAt: Date?
    @NSManaged public var lastError: String?
}

public final class CoreDataStack {
    public static let localModelVersion: LocalModelVersion = .v1

    public let container: NSPersistentContainer

    public var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    public init(inMemory: Bool = true) throws {
        container = NSPersistentContainer(
            name: "CoreDataRESTLayer",
            managedObjectModel: Self.makeModel()
        )

        let description = NSPersistentStoreDescription()
        if inMemory {
            description.type = NSInMemoryStoreType
        }
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]

        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }
        if let loadError {
            throw loadError
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    public static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let project = NSEntityDescription()
        project.name = "CDProject"
        project.managedObjectClassName = NSStringFromClass(CDProject.self)

        let projectId = attribute("id", .UUIDAttributeType, optional: false)
        let projectName = attribute("name", .stringAttributeType, optional: false)
        let projectUpdatedAt = attribute("updatedAt", .dateAttributeType, optional: false)
        let projectVersion = attribute("version", .integer64AttributeType, optional: false, defaultValue: 0)

        let task = NSEntityDescription()
        task.name = "CDTask"
        task.managedObjectClassName = NSStringFromClass(CDTask.self)

        let taskId = attribute("id", .UUIDAttributeType, optional: false)
        let taskTitle = attribute("title", .stringAttributeType, optional: false)
        let taskStatus = attribute("status", .stringAttributeType, optional: false)
        let taskNotes = attribute("notes", .stringAttributeType, optional: true)
        let taskLoadedFields = attribute("loadedFields", .stringAttributeType, optional: false, defaultValue: "summary")
        let taskUpdatedAt = attribute("updatedAt", .dateAttributeType, optional: false)
        let taskVersion = attribute("version", .integer64AttributeType, optional: false, defaultValue: 0)
        let taskIsDirty = attribute("isDirty", .booleanAttributeType, optional: false, defaultValue: false)
        let taskLastSyncError = attribute("lastSyncError", .stringAttributeType, optional: true)
        let taskConflictState = attribute("conflictState", .stringAttributeType, optional: true)

        let pendingTaskChange = NSEntityDescription()
        pendingTaskChange.name = "CDPendingTaskChange"
        pendingTaskChange.managedObjectClassName = NSStringFromClass(CDPendingTaskChange.self)

        let pendingId = attribute("id", .UUIDAttributeType, optional: false)
        let pendingTaskID = attribute("taskID", .UUIDAttributeType, optional: false)
        let pendingBaseVersion = attribute("baseVersion", .integer64AttributeType, optional: false, defaultValue: 0)
        let pendingTitle = attribute("title", .stringAttributeType, optional: false)
        let pendingStatus = attribute("status", .stringAttributeType, optional: false)
        let pendingChangedFields = attribute("changedFields", .stringAttributeType, optional: false)
        let pendingState = attribute("state", .stringAttributeType, optional: false, defaultValue: "pending")
        let pendingAttemptCount = attribute("attemptCount", .integer64AttributeType, optional: false, defaultValue: 0)
        let pendingCreatedAt = attribute("createdAt", .dateAttributeType, optional: false)
        let pendingUpdatedAt = attribute("updatedAt", .dateAttributeType, optional: false)
        let pendingLastAttemptedAt = attribute("lastAttemptedAt", .dateAttributeType, optional: true)
        let pendingLastError = attribute("lastError", .stringAttributeType, optional: true)
        let pendingConflictRemoteVersion = attribute("conflictRemoteVersion", .integer64AttributeType, optional: false, defaultValue: 0)
        let pendingConflictRemoteTitle = attribute("conflictRemoteTitle", .stringAttributeType, optional: true)
        let pendingConflictRemoteStatus = attribute("conflictRemoteStatus", .stringAttributeType, optional: true)

        let relationshipState = NSEntityDescription()
        relationshipState.name = "CDRemoteRelationshipState"
        relationshipState.managedObjectClassName = NSStringFromClass(CDRemoteRelationshipState.self)

        let stateId = attribute("id", .stringAttributeType, optional: false)
        let stateOwnerEntityName = attribute("ownerEntityName", .stringAttributeType, optional: false)
        let stateOwnerRemoteID = attribute("ownerRemoteID", .stringAttributeType, optional: false)
        let stateRelationshipName = attribute("relationshipName", .stringAttributeType, optional: false)
        let statePaginationMode = attribute("paginationMode", .stringAttributeType, optional: false)
        let stateIsComplete = attribute("isComplete", .booleanAttributeType, optional: false, defaultValue: false)
        let stateFetchedCount = attribute("fetchedCount", .integer64AttributeType, optional: false, defaultValue: 0)
        let stateTotalCount = attribute("totalCount", .integer64AttributeType, optional: false, defaultValue: 0)
        let stateNextCursor = attribute("nextCursor", .stringAttributeType, optional: true)
        let stateLastLoadedAt = attribute("lastLoadedAt", .dateAttributeType, optional: true)
        let stateLastError = attribute("lastError", .stringAttributeType, optional: true)

        let projectTasks = NSRelationshipDescription()
        projectTasks.name = "tasks"
        projectTasks.destinationEntity = task
        projectTasks.minCount = 0
        projectTasks.maxCount = 0
        projectTasks.deleteRule = .cascadeDeleteRule
        projectTasks.isOptional = true

        let taskProject = NSRelationshipDescription()
        taskProject.name = "project"
        taskProject.destinationEntity = project
        taskProject.minCount = 0
        taskProject.maxCount = 1
        taskProject.deleteRule = .nullifyDeleteRule
        taskProject.isOptional = true

        projectTasks.inverseRelationship = taskProject
        taskProject.inverseRelationship = projectTasks

        project.properties = [projectId, projectName, projectUpdatedAt, projectVersion, projectTasks]
        task.properties = [
            taskId,
            taskTitle,
            taskStatus,
            taskNotes,
            taskLoadedFields,
            taskUpdatedAt,
            taskVersion,
            taskIsDirty,
            taskLastSyncError,
            taskConflictState,
            taskProject
        ]
        pendingTaskChange.properties = [
            pendingId,
            pendingTaskID,
            pendingBaseVersion,
            pendingTitle,
            pendingStatus,
            pendingChangedFields,
            pendingState,
            pendingAttemptCount,
            pendingCreatedAt,
            pendingUpdatedAt,
            pendingLastAttemptedAt,
            pendingLastError,
            pendingConflictRemoteVersion,
            pendingConflictRemoteTitle,
            pendingConflictRemoteStatus
        ]
        relationshipState.properties = [
            stateId,
            stateOwnerEntityName,
            stateOwnerRemoteID,
            stateRelationshipName,
            statePaginationMode,
            stateIsComplete,
            stateFetchedCount,
            stateTotalCount,
            stateNextCursor,
            stateLastLoadedAt,
            stateLastError
        ]

        project.uniquenessConstraints = [["id"]]
        task.uniquenessConstraints = [["id"]]
        pendingTaskChange.uniquenessConstraints = [["id"]]
        relationshipState.uniquenessConstraints = [["id"]]

        model.entities = [project, task, pendingTaskChange, relationshipState]
        return model
    }

    private static func attribute(
        _ name: String,
        _ type: NSAttributeType,
        optional: Bool,
        defaultValue: Any? = nil
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        attribute.defaultValue = defaultValue
        return attribute
    }
}

public extension CDProject {
    static func fetchRequest() -> NSFetchRequest<CDProject> {
        NSFetchRequest<CDProject>(entityName: "CDProject")
    }

    static func fetchRequestSortedByName() -> NSFetchRequest<CDProject> {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return request
    }
}

public extension CDTask {
    var loadedFieldNames: Set<String> {
        Set(loadedFields.split(separator: ",").map(String.init))
    }

    func hasLoadedField(_ field: String) -> Bool {
        loadedFieldNames.contains(field)
    }

    static func fetchRequest() -> NSFetchRequest<CDTask> {
        NSFetchRequest<CDTask>(entityName: "CDTask")
    }

    static func fetchRequestSortedByTitle() -> NSFetchRequest<CDTask> {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        return request
    }
}

public extension CDPendingTaskChange {
    static func fetchRequest() -> NSFetchRequest<CDPendingTaskChange> {
        NSFetchRequest<CDPendingTaskChange>(entityName: "CDPendingTaskChange")
    }

    static func fetchRequestSortedByUpdatedAt() -> NSFetchRequest<CDPendingTaskChange> {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: true)]
        return request
    }
}

public extension CDRemoteRelationshipState {
    static func fetchRequest() -> NSFetchRequest<CDRemoteRelationshipState> {
        NSFetchRequest<CDRemoteRelationshipState>(entityName: "CDRemoteRelationshipState")
    }

    static func fetchRequestSortedByID() -> NSFetchRequest<CDRemoteRelationshipState> {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        return request
    }
}
