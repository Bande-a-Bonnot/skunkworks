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
    @NSManaged public var updatedAt: Date
    @NSManaged public var version: Int64
    @NSManaged public var isDirty: Bool
    @NSManaged public var lastSyncError: String?
    @NSManaged public var conflictState: String?
    @NSManaged public var project: CDProject?
}

public final class CoreDataStack {
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
        let taskUpdatedAt = attribute("updatedAt", .dateAttributeType, optional: false)
        let taskVersion = attribute("version", .integer64AttributeType, optional: false, defaultValue: 0)
        let taskIsDirty = attribute("isDirty", .booleanAttributeType, optional: false, defaultValue: false)
        let taskLastSyncError = attribute("lastSyncError", .stringAttributeType, optional: true)
        let taskConflictState = attribute("conflictState", .stringAttributeType, optional: true)

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
            taskUpdatedAt,
            taskVersion,
            taskIsDirty,
            taskLastSyncError,
            taskConflictState,
            taskProject
        ]

        project.uniquenessConstraints = [["id"]]
        task.uniquenessConstraints = [["id"]]

        model.entities = [project, task]
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
    static func fetchRequest() -> NSFetchRequest<CDTask> {
        NSFetchRequest<CDTask>(entityName: "CDTask")
    }

    static func fetchRequestSortedByTitle() -> NSFetchRequest<CDTask> {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        return request
    }
}
