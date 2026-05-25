import CoreData
@testable import CoreDataRESTLayer
import CoreDataRESTLayerTestServer
import XCTest

final class CoreDataRESTLayerTests: XCTestCase {
    func testRESTIncrementalStoreFetchesProjectsAndFaultsRelationshipThroughHTTP() throws {
        let fixture = Fixture.make()
        let server = EmbeddedRESTServer(projects: [fixture.project], tasks: fixture.tasks)
        try server.start()
        defer { server.stop() }

        let stack = try RESTCoreDataStack(baseURL: try server.baseURL)
        let projects = try stack.context.fetch(CDProject.fetchRequestSortedByName())

        let project = try XCTUnwrap(projects.first)
        XCTAssertEqual(project.name, "Skunkworks")
        XCTAssertEqual(server.requestCount(forPath: "/projects"), 1)

        let tasks = project.tasks.sorted { $0.title < $1.title }
        XCTAssertEqual(tasks.map(\.title), ["Project into Core Data", "Wire embedded server"])
        XCTAssertEqual(tasks.first?.project?.id, fixture.project.id)
        XCTAssertEqual(server.requestCount(forPath: "/projects/\(fixture.project.id.uuidString)/tasks"), 1)
    }

    func testRESTIncrementalStoreRelationshipFaultCanTraverseCursorPages() throws {
        let fixture = Fixture.make(taskCount: 5)
        let server = EmbeddedRESTServer(projects: [fixture.project], tasks: fixture.tasks)
        try server.start()
        defer { server.stop() }

        let stack = try RESTCoreDataStack(baseURL: try server.baseURL, taskPagination: .cursor(limit: 2))
        let project = try XCTUnwrap(stack.context.fetch(CDProject.fetchRequestSortedByName()).first)

        XCTAssertEqual(project.tasks.count, 5)
        XCTAssertEqual(server.requestCount(forPath: "/projects/\(fixture.project.id.uuidString)/tasks"), 3)
    }

    func testRESTIncrementalStoreKeepsPartialTaskDetailsExplicitUntilRefresh() throws {
        var fixture = Fixture.make()
        fixture.tasks[0].notes = nil
        fixture.tasks[1].notes = ""
        let server = EmbeddedRESTServer(projects: [fixture.project], tasks: fixture.tasks)
        try server.start()
        defer { server.stop() }

        let stack = try RESTCoreDataStack(baseURL: try server.baseURL)
        let project = try XCTUnwrap(stack.context.fetch(CDProject.fetchRequestSortedByName()).first)
        let tasks = project.tasks.sorted { $0.title < $1.title }
        let nullNotesTask = try XCTUnwrap(tasks.first { $0.id == fixture.firstTaskID })
        let emptyNotesTask = try XCTUnwrap(tasks.first { $0.id != fixture.firstTaskID })

        XCTAssertNil(nullNotesTask.notes)
        XCTAssertFalse(nullNotesTask.hasLoadedField("notes"))
        XCTAssertEqual(nullNotesTask.loadedFields, "summary")
        XCTAssertNil(emptyNotesTask.notes)
        XCTAssertFalse(emptyNotesTask.hasLoadedField("notes"))
        XCTAssertEqual(server.requestCount(forPath: "/tasks/\(fixture.firstTaskID.uuidString)"), 0)

        try stack.loadTaskDetails(for: nullNotesTask)
        XCTAssertNil(nullNotesTask.notes)
        XCTAssertTrue(nullNotesTask.hasLoadedField("notes"))
        XCTAssertEqual(nullNotesTask.loadedFields, "summary,notes")
        XCTAssertEqual(server.requestCount(forPath: "/tasks/\(fixture.firstTaskID.uuidString)"), 1)

        try stack.loadTaskDetails(for: emptyNotesTask)
        XCTAssertEqual(emptyNotesTask.notes, "")
        XCTAssertTrue(emptyNotesTask.hasLoadedField("notes"))
    }

    func testRESTIncrementalStoreRelationshipFaultWritesCompletenessState() throws {
        let fixture = Fixture.make(taskCount: 5)
        let server = EmbeddedRESTServer(projects: [fixture.project], tasks: fixture.tasks)
        try server.start()
        defer { server.stop() }

        let stack = try RESTCoreDataStack(baseURL: try server.baseURL, taskPagination: .cursor(limit: 2))
        let project = try XCTUnwrap(stack.context.fetch(CDProject.fetchRequestSortedByName()).first)
        XCTAssertTrue(try stack.context.fetch(CDRemoteRelationshipState.fetchRequest()).isEmpty)

        XCTAssertEqual(project.tasks.count, 5)

        let states = try stack.context.fetch(CDRemoteRelationshipState.fetchRequestSortedByID())
        let state = try XCTUnwrap(states.first)
        XCTAssertEqual(states.count, 1)
        XCTAssertEqual(state.ownerEntityName, "CDProject")
        XCTAssertEqual(state.ownerRemoteID, fixture.project.id.uuidString)
        XCTAssertEqual(state.relationshipName, "tasks")
        XCTAssertEqual(state.paginationMode, "cursor(limit:2)")
        XCTAssertTrue(state.isComplete)
        XCTAssertEqual(state.fetchedCount, 5)
        XCTAssertEqual(state.totalCount, 5)
        XCTAssertNil(state.nextCursor)
        XCTAssertNotNil(state.lastLoadedAt)
        XCTAssertNil(state.lastError)
    }

    func testRESTIncrementalStoreRelationshipFaultFailureWritesIncompleteState() throws {
        let fixture = Fixture.make(taskCount: 5)
        let server = EmbeddedRESTServer(projects: [fixture.project], tasks: fixture.tasks)
        try server.start()
        defer { server.stop() }

        let stack = try RESTCoreDataStack(baseURL: try server.baseURL, taskPagination: .cursor(limit: 2))
        let project = try XCTUnwrap(stack.context.fetch(CDProject.fetchRequestSortedByName()).first)
        server.setForcedResponse(
            status: 502,
            body: "tasks unavailable",
            forPathPrefix: "/projects/\(fixture.project.id.uuidString)/tasks",
            method: "GET"
        )

        let store = try XCTUnwrap(stack.coordinator.persistentStores.first as? RESTIncrementalStore)
        let relationship = try XCTUnwrap(project.entity.relationshipsByName["tasks"])
        XCTAssertThrowsError(
            try store.newValue(forRelationship: relationship, forObjectWith: project.objectID, with: stack.context)
        )

        let state = try XCTUnwrap(stack.context.fetch(CDRemoteRelationshipState.fetchRequestSortedByID()).first)
        XCTAssertEqual(state.paginationMode, "cursor(limit:2)")
        XCTAssertFalse(state.isComplete)
        XCTAssertEqual(state.fetchedCount, 0)
        XCTAssertEqual(state.totalCount, 0)
        XCTAssertNil(state.lastLoadedAt)
        XCTAssertTrue(state.lastError?.contains("tasks unavailable") == true)
    }

    func testRESTIncrementalStoreRelationshipFaultCanTraverseOffsetPages() throws {
        let fixture = Fixture.make(taskCount: 5)
        let server = EmbeddedRESTServer(projects: [fixture.project], tasks: fixture.tasks)
        try server.start()
        defer { server.stop() }

        let stack = try RESTCoreDataStack(baseURL: try server.baseURL, taskPagination: .offset(limit: 2))
        let project = try XCTUnwrap(stack.context.fetch(CDProject.fetchRequestSortedByName()).first)

        XCTAssertEqual(project.tasks.count, 5)
        XCTAssertEqual(server.requestCount(forPath: "/projects/\(fixture.project.id.uuidString)/tasks"), 3)
    }

    func testRESTIncrementalStoreRelationshipFaultCanTraverseNumberedPages() throws {
        let fixture = Fixture.make(taskCount: 5)
        let server = EmbeddedRESTServer(projects: [fixture.project], tasks: fixture.tasks)
        try server.start()
        defer { server.stop() }

        let stack = try RESTCoreDataStack(baseURL: try server.baseURL, taskPagination: .numberedPages(perPage: 2))
        let project = try XCTUnwrap(stack.context.fetch(CDProject.fetchRequestSortedByName()).first)

        XCTAssertEqual(project.tasks.count, 5)
        XCTAssertEqual(server.requestCount(forPath: "/projects/\(fixture.project.id.uuidString)/tasks"), 3)
    }

    func testRESTIncrementalStoreSavePatchesTaskThroughHTTP() throws {
        let fixture = Fixture.make()
        let server = EmbeddedRESTServer(projects: [fixture.project], tasks: fixture.tasks)
        try server.start()
        defer { server.stop() }

        let stack = try RESTCoreDataStack(baseURL: try server.baseURL)
        let projects = try stack.context.fetch(CDProject.fetchRequestSortedByName())
        let project = try XCTUnwrap(projects.first)
        let task = try XCTUnwrap(project.tasks.first { $0.id == fixture.firstTaskID })

        task.title = "Saved by Core Data store"
        task.status = "done"
        try stack.context.save()

        let remoteTask = try server.currentTask(id: fixture.firstTaskID)
        XCTAssertEqual(remoteTask.title, "Saved by Core Data store")
        XCTAssertEqual(remoteTask.status, "done")
        XCTAssertEqual(remoteTask.version, 2)
        XCTAssertEqual(task.version, 2)
        XCTAssertEqual(server.requestCount(forPath: "/tasks/\(fixture.firstTaskID.uuidString)"), 1)
    }

    func testRESTIncrementalStoreFetchHTTPErrorThrowsTypedStatus() throws {
        let fixture = Fixture.make()
        let server = EmbeddedRESTServer(projects: [fixture.project], tasks: fixture.tasks)
        try server.start()
        defer { server.stop() }
        server.setForcedResponse(status: 503, body: "projects unavailable", forPathPrefix: "/projects", method: "GET")

        let stack = try RESTCoreDataStack(baseURL: try server.baseURL)

        XCTAssertThrowsError(try stack.context.fetch(CDProject.fetchRequestSortedByName())) { error in
            assertHTTPStatus(error, status: 503, bodyContains: "projects unavailable")
        }
    }

    func testRESTIncrementalStoreRelationshipFaultHTTPErrorThrowsTypedStatus() throws {
        let fixture = Fixture.make()
        let server = EmbeddedRESTServer(projects: [fixture.project], tasks: fixture.tasks)
        try server.start()
        defer { server.stop() }

        let stack = try RESTCoreDataStack(baseURL: try server.baseURL)
        let project = try XCTUnwrap(stack.context.fetch(CDProject.fetchRequestSortedByName()).first)
        server.setForcedResponse(
            status: 502,
            body: "tasks unavailable",
            forPathPrefix: "/projects/\(fixture.project.id.uuidString)/tasks",
            method: "GET"
        )

        let store = try XCTUnwrap(stack.coordinator.persistentStores.first as? RESTIncrementalStore)
        let relationship = try XCTUnwrap(project.entity.relationshipsByName["tasks"])
        XCTAssertThrowsError(
            try store.newValue(forRelationship: relationship, forObjectWith: project.objectID, with: stack.context)
        ) { error in
            assertHTTPStatus(error, status: 502, bodyContains: "tasks unavailable")
        }
    }

    func testRESTIncrementalStoreSaveHTTPErrorThrowsTypedStatus() throws {
        let fixture = Fixture.make()
        let server = EmbeddedRESTServer(projects: [fixture.project], tasks: fixture.tasks)
        try server.start()
        defer { server.stop() }

        let stack = try RESTCoreDataStack(baseURL: try server.baseURL)
        let project = try XCTUnwrap(stack.context.fetch(CDProject.fetchRequestSortedByName()).first)
        let task = try XCTUnwrap(project.tasks.first { $0.id == fixture.firstTaskID })
        server.setForcedResponse(
            status: 500,
            body: "save unavailable",
            forPathPrefix: "/tasks/\(fixture.firstTaskID.uuidString)",
            method: "PATCH"
        )

        task.title = "Will fail"
        XCTAssertThrowsError(try stack.context.save()) { error in
            assertHTTPStatus(error, status: 500, bodyContains: "save unavailable")
        }
    }

    func testRESTIncrementalStoreBackgroundContextCanRunBlockingRESTWorkOffMainContext() throws {
        let fixture = Fixture.make()
        let server = EmbeddedRESTServer(projects: [fixture.project], tasks: fixture.tasks)
        try server.start()
        defer { server.stop() }

        let stack = try RESTCoreDataStack(baseURL: try server.baseURL)
        let context = stack.makeBackgroundContext()
        let fetchedNames = try context.performAndWait {
            try context.fetch(CDProject.fetchRequestSortedByName()).map(\.name)
        }

        XCTAssertEqual(fetchedNames, ["Skunkworks"])
    }

    func testRESTIncrementalStoreStagingPendingChangeDoesNotMutateSnapshotOrPatch() throws {
        let fixture = Fixture.make()
        let server = EmbeddedRESTServer(projects: [fixture.project], tasks: fixture.tasks)
        try server.start()
        defer { server.stop() }

        let stack = try RESTCoreDataStack(baseURL: try server.baseURL)
        let project = try XCTUnwrap(stack.context.fetch(CDProject.fetchRequestSortedByName()).first)
        let task = try XCTUnwrap(project.tasks.first { $0.id == fixture.firstTaskID })

        let change = try stack.stageTaskUpdate(for: task, title: "Pending local title", status: "done")

        XCTAssertEqual(task.title, "Wire embedded server")
        XCTAssertEqual(task.status, "open")
        XCTAssertEqual(try server.currentTask(id: fixture.firstTaskID).title, "Wire embedded server")
        XCTAssertEqual(server.requestCount(forPath: "/tasks/\(fixture.firstTaskID.uuidString)"), 0)
        XCTAssertEqual(change.taskID, fixture.firstTaskID)
        XCTAssertEqual(change.baseVersion, 1)
        XCTAssertEqual(change.title, "Pending local title")
        XCTAssertEqual(change.status, "done")
        XCTAssertEqual(change.changedFields, "title,status")
        XCTAssertEqual(change.state, "pending")

        let changes = try stack.context.fetch(CDPendingTaskChange.fetchRequest())
        XCTAssertEqual(changes.count, 1)
    }

    func testRESTIncrementalStoreFlushPendingChangePatchesServerAndClearsPending() throws {
        let fixture = Fixture.make()
        let server = EmbeddedRESTServer(projects: [fixture.project], tasks: fixture.tasks)
        try server.start()
        defer { server.stop() }

        let stack = try RESTCoreDataStack(baseURL: try server.baseURL)
        let project = try XCTUnwrap(stack.context.fetch(CDProject.fetchRequestSortedByName()).first)
        let task = try XCTUnwrap(project.tasks.first { $0.id == fixture.firstTaskID })
        _ = try stack.stageTaskUpdate(for: task, title: "Applied pending title", status: "done")

        let outcomes = try stack.flushPendingTaskChanges()

        XCTAssertEqual(outcomes, [.applied(fixture.firstTaskID)])
        XCTAssertEqual(server.requestCount(forPath: "/tasks/\(fixture.firstTaskID.uuidString)"), 1)
        let remote = try server.currentTask(id: fixture.firstTaskID)
        XCTAssertEqual(remote.title, "Applied pending title")
        XCTAssertEqual(remote.status, "done")
        XCTAssertEqual(remote.version, 2)
        XCTAssertEqual(task.title, "Applied pending title")
        XCTAssertEqual(task.status, "done")
        XCTAssertEqual(task.version, 2)
        XCTAssertFalse(task.isDirty)
        XCTAssertTrue(try stack.context.fetch(CDPendingTaskChange.fetchRequest()).isEmpty)
    }

    func testRESTIncrementalStorePendingChangeConflictKeepsLocalAttemptSeparateFromRemoteSnapshot() throws {
        let fixture = Fixture.make()
        let server = EmbeddedRESTServer(projects: [fixture.project], tasks: fixture.tasks)
        try server.start()
        defer { server.stop() }

        let stack = try RESTCoreDataStack(baseURL: try server.baseURL)
        let project = try XCTUnwrap(stack.context.fetch(CDProject.fetchRequestSortedByName()).first)
        let task = try XCTUnwrap(project.tasks.first { $0.id == fixture.firstTaskID })
        _ = try stack.stageTaskUpdate(for: task, title: "Local pending attempt", status: "done")
        try server.mutateTask(id: fixture.firstTaskID) { task in
            task.title = "Remote changed first"
            task.status = "blocked"
            task.version = 2
            task.updatedAt = Fixture.laterDate
        }

        let outcomes = try stack.flushPendingTaskChanges()

        XCTAssertEqual(outcomes, [.conflict(fixture.firstTaskID, remoteVersion: 2)])
        let change = try XCTUnwrap(stack.context.fetch(CDPendingTaskChange.fetchRequest()).first)
        XCTAssertEqual(change.state, "conflicted")
        XCTAssertEqual(change.title, "Local pending attempt")
        XCTAssertEqual(change.status, "done")
        XCTAssertEqual(change.conflictRemoteVersion, 2)
        XCTAssertEqual(change.conflictRemoteTitle, "Remote changed first")
        XCTAssertEqual(change.conflictRemoteStatus, "blocked")
        XCTAssertEqual(task.title, "Remote changed first")
        XCTAssertEqual(task.status, "blocked")
        XCTAssertEqual(task.version, 2)
    }

    func testRESTIncrementalStorePendingChangeHTTPFailureCanRetry() throws {
        let fixture = Fixture.make()
        let server = EmbeddedRESTServer(projects: [fixture.project], tasks: fixture.tasks)
        try server.start()
        defer { server.stop() }

        let stack = try RESTCoreDataStack(baseURL: try server.baseURL)
        let project = try XCTUnwrap(stack.context.fetch(CDProject.fetchRequestSortedByName()).first)
        let task = try XCTUnwrap(project.tasks.first { $0.id == fixture.firstTaskID })
        _ = try stack.stageTaskUpdate(for: task, title: "Retry pending title", status: "done")
        let path = "/tasks/\(fixture.firstTaskID.uuidString)"
        server.setForcedResponse(status: 500, body: "save unavailable", forPathPrefix: path, method: "PATCH")

        let failedOutcomes = try stack.flushPendingTaskChanges()

        XCTAssertEqual(failedOutcomes.count, 1)
        guard case .failed(let failedTaskID, let message) = failedOutcomes.first else {
            return XCTFail("Expected failed pending outcome")
        }
        XCTAssertEqual(failedTaskID, fixture.firstTaskID)
        XCTAssertTrue(message.contains("save unavailable"))
        let change = try XCTUnwrap(stack.context.fetch(CDPendingTaskChange.fetchRequest()).first)
        XCTAssertEqual(change.state, "failed")
        XCTAssertEqual(change.attemptCount, 1)
        XCTAssertTrue(change.lastError?.contains("save unavailable") == true)

        server.clearForcedResponse(forPathPrefix: path)
        let retryOutcomes = try stack.flushPendingTaskChanges()

        XCTAssertEqual(retryOutcomes, [.applied(fixture.firstTaskID)])
        XCTAssertEqual(server.requestCount(forPath: path), 2)
        XCTAssertEqual(try server.currentTask(id: fixture.firstTaskID).title, "Retry pending title")
        XCTAssertTrue(try stack.context.fetch(CDPendingTaskChange.fetchRequest()).isEmpty)
    }

    func testRESTIncrementalStoreRepeatedStagingCoalescesPendingChange() throws {
        let fixture = Fixture.make()
        let server = EmbeddedRESTServer(projects: [fixture.project], tasks: fixture.tasks)
        try server.start()
        defer { server.stop() }

        let stack = try RESTCoreDataStack(baseURL: try server.baseURL)
        let project = try XCTUnwrap(stack.context.fetch(CDProject.fetchRequestSortedByName()).first)
        let task = try XCTUnwrap(project.tasks.first { $0.id == fixture.firstTaskID })
        let first = try stack.stageTaskUpdate(for: task, title: "First pending title", status: "open")
        let second = try stack.stageTaskUpdate(for: task, title: "Second pending title", status: "done")

        XCTAssertEqual(first.id, second.id)
        let changes = try stack.context.fetch(CDPendingTaskChange.fetchRequest())
        let change = try XCTUnwrap(changes.first)
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(change.baseVersion, 1)
        XCTAssertEqual(change.title, "Second pending title")
        XCTAssertEqual(change.status, "done")
        XCTAssertEqual(change.state, "pending")
        XCTAssertEqual(server.requestCount(forPath: "/tasks/\(fixture.firstTaskID.uuidString)"), 0)
    }

    func testRESTIncrementalStoreSaveConflictMarksObjectAndThrows() throws {
        let fixture = Fixture.make()
        let server = EmbeddedRESTServer(projects: [fixture.project], tasks: fixture.tasks)
        try server.start()
        defer { server.stop() }

        let stack = try RESTCoreDataStack(baseURL: try server.baseURL)
        let project = try XCTUnwrap(stack.context.fetch(CDProject.fetchRequestSortedByName()).first)
        let task = try XCTUnwrap(project.tasks.first { $0.id == fixture.firstTaskID })

        try server.mutateTask(id: fixture.firstTaskID) { task in
            task.title = "Remote won first"
            task.status = "blocked"
            task.version = 2
            task.updatedAt = Fixture.laterDate
        }

        task.title = "Local stale edit through Core Data save"
        task.status = "done"

        XCTAssertThrowsError(try stack.context.save()) { error in
            guard case RESTIncrementalStoreError.conflict(let remote) = error else {
                return XCTFail("Expected RESTIncrementalStoreError.conflict, got \(error)")
            }
            XCTAssertEqual(remote.version, 2)
        }
        XCTAssertTrue(task.isDirty)
        XCTAssertEqual(task.conflictState, "remoteVersion=2")
        XCTAssertTrue(task.lastSyncError?.contains("Remote won first") == true)
    }

    func testSyncEditAndPushRoundTripThroughHTTP() async throws {
        let fixture = Fixture.make()
        let server = EmbeddedRESTServer(projects: [fixture.project], tasks: fixture.tasks)
        try server.start()
        defer { server.stop() }

        let stack = try CoreDataStack()
        let client = RESTClient(baseURL: try server.baseURL)
        let sync = ProjectionSync(context: stack.viewContext, client: client)

        try await sync.pullAll()

        let projects = try stack.viewContext.fetch(CDProject.fetchRequestSortedByName())
        XCTAssertEqual(projects.count, 1)
        XCTAssertEqual(projects.first?.name, "Skunkworks")
        XCTAssertEqual(projects.first?.tasks.count, 2)

        let task = try XCTUnwrap(fetchTask(id: fixture.firstTaskID, in: stack.viewContext))
        XCTAssertEqual(task.project?.id, fixture.project.id)
        XCTAssertEqual(task.version, 1)

        task.title = "Wire embedded server over real HTTP"
        task.status = "done"
        task.isDirty = true
        try stack.viewContext.save()

        let outcomes = try await sync.pushDirtyTasks()
        XCTAssertEqual(outcomes, [.pushed(fixture.firstTaskID)])

        let pushedTask = try XCTUnwrap(fetchTask(id: fixture.firstTaskID, in: stack.viewContext))
        XCTAssertEqual(pushedTask.title, "Wire embedded server over real HTTP")
        XCTAssertEqual(pushedTask.status, "done")
        XCTAssertEqual(pushedTask.version, 2)
        XCTAssertFalse(pushedTask.isDirty)
        XCTAssertNil(pushedTask.lastSyncError)
        XCTAssertNil(pushedTask.conflictState)

        let remoteTask = try server.currentTask(id: fixture.firstTaskID)
        XCTAssertEqual(remoteTask.title, "Wire embedded server over real HTTP")
        XCTAssertEqual(remoteTask.status, "done")
        XCTAssertEqual(remoteTask.version, 2)
    }

    func testPullAllCanTraversePaginatedTaskResponses() async throws {
        let fixture = Fixture.make(taskCount: 5)
        let server = EmbeddedRESTServer(projects: [fixture.project], tasks: fixture.tasks)
        try server.start()
        defer { server.stop() }

        let stack = try CoreDataStack()
        let client = RESTClient(baseURL: try server.baseURL)
        let sync = ProjectionSync(context: stack.viewContext, client: client, taskPageSize: 2)

        let firstPage = try await client.fetchTaskCursorPage(projectID: fixture.project.id, limit: 2)
        XCTAssertEqual(firstPage.items.count, 2)
        XCTAssertEqual(firstPage.nextCursor, "2")

        try await sync.pullAll()

        let tasks = try stack.viewContext.fetch(CDTask.fetchRequestSortedByTitle())
        XCTAssertEqual(tasks.count, 5)

        let project = try XCTUnwrap(stack.viewContext.fetch(CDProject.fetchRequestSortedByName()).first)
        XCTAssertEqual(project.tasks.count, 5)
    }

    func testPullAllCanTraverseOffsetTaskResponses() async throws {
        let fixture = Fixture.make(taskCount: 5)
        let server = EmbeddedRESTServer(projects: [fixture.project], tasks: fixture.tasks)
        try server.start()
        defer { server.stop() }

        let stack = try CoreDataStack()
        let client = RESTClient(baseURL: try server.baseURL)
        let sync = ProjectionSync(context: stack.viewContext, client: client, taskPagination: .offset(limit: 2))

        let firstPage = try await client.fetchTaskOffsetPage(projectID: fixture.project.id, limit: 2, offset: 0)
        XCTAssertEqual(firstPage.count, 2)

        try await sync.pullAll()
        XCTAssertEqual(try stack.viewContext.fetch(CDTask.fetchRequest()).count, 5)
    }

    func testPullAllCanTraverseNumberedTaskPages() async throws {
        let fixture = Fixture.make(taskCount: 5)
        let server = EmbeddedRESTServer(projects: [fixture.project], tasks: fixture.tasks)
        try server.start()
        defer { server.stop() }

        let stack = try CoreDataStack()
        let client = RESTClient(baseURL: try server.baseURL)
        let sync = ProjectionSync(context: stack.viewContext, client: client, taskPagination: .numberedPages(perPage: 2))

        let firstPage = try await client.fetchTaskNumberedPage(projectID: fixture.project.id, page: 1, perPage: 2)
        XCTAssertEqual(firstPage.items.count, 2)
        XCTAssertEqual(firstPage.page, 1)
        XCTAssertEqual(firstPage.totalPages, 3)

        try await sync.pullAll()
        XCTAssertEqual(try stack.viewContext.fetch(CDTask.fetchRequest()).count, 5)
    }

    func testClientSendsAPIAndLocalModelVersionHeaders() async throws {
        let fixture = Fixture.make()
        let server = EmbeddedRESTServer(projects: [fixture.project], tasks: fixture.tasks)
        try server.start()
        defer { server.stop() }

        let client = RESTClient(baseURL: try server.baseURL)
        _ = try await client.fetchProjects()

        XCTAssertEqual(server.lastRequestHeader("X-API-Version"), APIVersion.v1.rawValue)
        XCTAssertEqual(server.lastRequestHeader("X-Local-Model-Version"), String(CoreDataStack.localModelVersion.rawValue))
    }

    func testServerCanInjectEndpointLatency() async throws {
        let fixture = Fixture.make()
        let server = EmbeddedRESTServer(projects: [fixture.project], tasks: fixture.tasks)
        try server.start()
        defer { server.stop() }
        server.setLatency(0.05, forPathPrefix: "/projects")

        let client = RESTClient(baseURL: try server.baseURL)
        let start = Date()
        _ = try await client.fetchProjects()

        XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(start), 0.04)
    }

    func testStaleLocalEditRecordsConflictWithoutOverwritingLocalAttempt() async throws {
        let fixture = Fixture.make()
        let server = EmbeddedRESTServer(projects: [fixture.project], tasks: fixture.tasks)
        try server.start()
        defer { server.stop() }

        let stack = try CoreDataStack()
        let client = RESTClient(baseURL: try server.baseURL)
        let sync = ProjectionSync(context: stack.viewContext, client: client)

        try await sync.pullAll()

        try server.mutateTask(id: fixture.firstTaskID) { task in
            task.title = "Remote won first"
            task.status = "blocked"
            task.version = 2
            task.updatedAt = Fixture.laterDate
        }

        let task = try XCTUnwrap(fetchTask(id: fixture.firstTaskID, in: stack.viewContext))
        XCTAssertEqual(task.version, 1)
        task.title = "Local stale edit"
        task.status = "done"
        task.isDirty = true
        try stack.viewContext.save()

        let outcomes = try await sync.pushDirtyTasks()
        XCTAssertEqual(outcomes, [.conflict(fixture.firstTaskID, remoteVersion: 2)])

        let conflictedTask = try XCTUnwrap(fetchTask(id: fixture.firstTaskID, in: stack.viewContext))
        XCTAssertEqual(conflictedTask.title, "Local stale edit")
        XCTAssertEqual(conflictedTask.status, "done")
        XCTAssertEqual(conflictedTask.version, 1)
        XCTAssertTrue(conflictedTask.isDirty)
        XCTAssertEqual(conflictedTask.conflictState, "remoteVersion=2")
        XCTAssertTrue(conflictedTask.lastSyncError?.contains("Remote won first") == true)
    }

    private func assertHTTPStatus(
        _ error: Error,
        status: Int,
        bodyContains expectedBodyFragment: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case RESTIncrementalStoreError.httpStatus(let actualStatus, let body) = error else {
            return XCTFail("Expected RESTIncrementalStoreError.httpStatus, got \(error)", file: file, line: line)
        }
        XCTAssertEqual(actualStatus, status, file: file, line: line)
        XCTAssertTrue(body.contains(expectedBodyFragment), file: file, line: line)

        let nsError = error as NSError
        XCTAssertEqual(nsError.domain, RESTIncrementalStoreError.errorDomain, file: file, line: line)
        XCTAssertEqual(nsError.code, RESTIncrementalStoreError.httpStatus(status, "").errorCode, file: file, line: line)
        XCTAssertEqual(nsError.userInfo["HTTPStatusCode"] as? Int, status, file: file, line: line)
    }

    private func fetchTask(id: UUID, in context: NSManagedObjectContext) throws -> CDTask? {
        let request = CDTask.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as NSUUID)
        return try context.fetch(request).first
    }
}

private struct Fixture {
    static let baseDate = ISO8601DateFormatter().date(from: "2026-05-22T00:00:00Z")!
    static let laterDate = ISO8601DateFormatter().date(from: "2026-05-22T00:10:00Z")!

    var project: RemoteProject
    var tasks: [RemoteTask]
    var firstTaskID: UUID

    static func make(taskCount: Int = 2) -> Fixture {
        let projectID = UUID(uuidString: "019e5066-a278-7de1-9e10-f1fd49f20a21")!
        let firstTaskID = UUID(uuidString: "019e5066-ce73-7c9b-a401-c65be5a86d74")!
        let secondTaskID = UUID(uuidString: "019e5067-0a52-7c3f-9ea8-99d4b498b5b6")!

        let project = RemoteProject(
            id: projectID,
            name: "Skunkworks",
            updatedAt: baseDate,
            version: 1
        )
        var tasks = [
            RemoteTask(
                id: firstTaskID,
                projectId: projectID,
                title: "Wire embedded server",
                status: "open",
                updatedAt: baseDate,
                version: 1
            ),
            RemoteTask(
                id: secondTaskID,
                projectId: projectID,
                title: "Project into Core Data",
                status: "open",
                updatedAt: baseDate,
                version: 1
            )
        ]

        if taskCount > tasks.count {
            for index in (tasks.count + 1)...taskCount {
                tasks.append(
                    RemoteTask(
                        id: UUID(),
                        projectId: projectID,
                        title: String(format: "Extra task %02d", index),
                        status: "open",
                        updatedAt: baseDate,
                        version: 1
                    )
                )
            }
        }

        return Fixture(project: project, tasks: Array(tasks.prefix(taskCount)), firstTaskID: firstTaskID)
    }
}
