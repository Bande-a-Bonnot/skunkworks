import CoreData
@testable import CoreDataRESTLayer
import CoreDataRESTLayerTestServer
import XCTest

final class CoreDataRESTLayerTests: XCTestCase {
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
