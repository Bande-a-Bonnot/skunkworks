import CoreData
import Foundation

public enum PushOutcome: Equatable {
    case pushed(UUID)
    case conflict(UUID, remoteVersion: Int)
}

public final class ProjectionSync {
    private let context: NSManagedObjectContext
    private let client: RESTClient
    private let taskPagination: TaskPaginationStrategy

    public init(
        context: NSManagedObjectContext,
        client: RESTClient,
        taskPagination: TaskPaginationStrategy = .none
    ) {
        self.context = context
        self.client = client
        self.taskPagination = taskPagination
    }

    public convenience init(context: NSManagedObjectContext, client: RESTClient, taskPageSize: Int?) {
        self.init(
            context: context,
            client: client,
            taskPagination: taskPageSize.map { .cursor(limit: $0) } ?? .none
        )
    }

    public func pullAll() async throws {
        let projects = try await client.fetchProjects()
        var tasksByProjectID: [UUID: [RemoteTask]] = [:]
        for project in projects {
            tasksByProjectID[project.id] = try await client.fetchTasks(projectID: project.id, pagination: taskPagination)
        }

        try await context.perform {
            for project in projects {
                let localProject = try self.fetchOrInsertProject(id: project.id)
                localProject.name = project.name
                localProject.updatedAt = project.updatedAt
                localProject.version = Int64(project.version)

                for task in tasksByProjectID[project.id, default: []] {
                    let localTask = try self.fetchOrInsertTask(id: task.id)
                    localTask.title = task.title
                    localTask.status = task.status
                    localTask.notes = task.notes
                    localTask.loadedFields = task.loadedFieldsDescription
                    localTask.updatedAt = task.updatedAt
                    localTask.version = Int64(task.version)
                    localTask.project = localProject

                    // A pull represents accepted remote truth, so clear stale sync metadata.
                    localTask.isDirty = false
                    localTask.lastSyncError = nil
                    localTask.conflictState = nil
                }
            }

            if self.context.hasChanges {
                try self.context.save()
            }
        }
    }

    public func pushDirtyTasks() async throws -> [PushOutcome] {
        let snapshots = try await context.perform {
            let request = CDTask.fetchRequest()
            request.predicate = NSPredicate(format: "isDirty == YES")
            request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
            return try self.context.fetch(request).map {
                DirtyTaskSnapshot(
                    objectID: $0.objectID,
                    id: $0.id,
                    title: $0.title,
                    status: $0.status,
                    version: Int($0.version)
                )
            }
        }

        var outcomes: [PushOutcome] = []
        for snapshot in snapshots {
            do {
                let remote = try await client.patchTask(
                    id: snapshot.id,
                    title: snapshot.title,
                    status: snapshot.status,
                    version: snapshot.version
                )
                try await context.perform {
                    guard let task = try self.context.existingObject(with: snapshot.objectID) as? CDTask else {
                        return
                    }
                    task.title = remote.title
                    task.status = remote.status
                    task.updatedAt = remote.updatedAt
                    task.version = Int64(remote.version)
                    task.isDirty = false
                    task.lastSyncError = nil
                    task.conflictState = nil
                    try self.context.saveIfNeeded()
                }
                outcomes.append(.pushed(snapshot.id))
            } catch RESTClientError.conflict(let remote) {
                try await context.perform {
                    guard let task = try self.context.existingObject(with: snapshot.objectID) as? CDTask else {
                        return
                    }
                    // Preserve the local attempted values and version; record enough remote state
                    // for app code to choose a merge/overwrite/reload action explicitly.
                    task.lastSyncError = "Conflict: remote version \(remote.version) has title '\(remote.title)' and status '\(remote.status)'"
                    task.conflictState = "remoteVersion=\(remote.version)"
                    task.isDirty = true
                    try self.context.saveIfNeeded()
                }
                outcomes.append(.conflict(snapshot.id, remoteVersion: remote.version))
            }
        }
        return outcomes
    }

    private func fetchOrInsertProject(id: UUID) throws -> CDProject {
        let request = CDProject.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as NSUUID)
        if let existing = try context.fetch(request).first {
            return existing
        }
        let project = CDProject(context: context)
        project.id = id
        return project
    }

    private func fetchOrInsertTask(id: UUID) throws -> CDTask {
        let request = CDTask.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as NSUUID)
        if let existing = try context.fetch(request).first {
            return existing
        }
        let task = CDTask(context: context)
        task.id = id
        return task
    }
}

private extension RemoteTask {
    var loadedFieldsDescription: String {
        isDetailLoaded
            ? MetadataListCodec.encode(Set(TaskLoadedField.allCases))
            : TaskLoadedField.summary.rawValue
    }
}

private struct DirtyTaskSnapshot {
    var objectID: NSManagedObjectID
    var id: UUID
    var title: String
    var status: String
    var version: Int
}

private extension NSManagedObjectContext {
    func saveIfNeeded() throws {
        if hasChanges {
            try save()
        }
    }
}
