import XCTest
@testable import CoreDataGraphDB

final class GraphAlgorithmsTests: XCTestCase {
    func testManagedAndSnapshotBFSReturnDeterministicOrder() throws {
        let store = try GraphStore()
        let nodes = try store.seedBFSFixture()
        let start = try XCTUnwrap(nodes["A"])

        let managedIDs = GraphAlgorithms.breadthFirstManaged(from: start)
        let snapshot = try GraphAlgorithms.makeSnapshot(context: store.context)
        let snapshotIDs = GraphAlgorithms.breadthFirstSnapshot(from: start.id, in: snapshot)

        XCTAssertEqual(managedIDs.map(snapshot.label(for:)), ["A", "B", "C", "D", "E"])
        XCTAssertEqual(snapshotIDs.map(snapshot.label(for:)), ["A", "B", "C", "D", "E"])
        XCTAssertEqual(snapshotIDs, managedIDs)
    }

    func testManagedAndSnapshotDijkstraReturnShortestPath() throws {
        let store = try GraphStore()
        let nodes = try store.seedDijkstraFixture()
        let start = try XCTUnwrap(nodes["A"])
        let target = try XCTUnwrap(nodes["D"])

        let managed = try XCTUnwrap(GraphAlgorithms.dijkstraManaged(from: start, to: target))
        let snapshot = try GraphAlgorithms.makeSnapshot(context: store.context)
        let snapshotted = try XCTUnwrap(GraphAlgorithms.dijkstraSnapshot(from: start.id, to: target.id, in: snapshot))

        XCTAssertEqual(managed.nodeIDs.map(snapshot.label(for:)), ["A", "C", "B", "D"])
        XCTAssertEqual(managed.totalWeight, 4)
        XCTAssertEqual(snapshotted.nodeIDs.map(snapshot.label(for:)), ["A", "C", "B", "D"])
        XCTAssertEqual(snapshotted.totalWeight, 4)
        XCTAssertEqual(snapshotted, managed)
    }

    func testDijkstraReturnsNilWhenTargetIsUnreachable() throws {
        let store = try GraphStore()
        let a = store.createNode(label: "A")
        let b = store.createNode(label: "B")
        try store.saveIfNeeded()

        let snapshot = try GraphAlgorithms.makeSnapshot(context: store.context)

        XCTAssertNil(GraphAlgorithms.dijkstraManaged(from: a, to: b))
        XCTAssertNil(GraphAlgorithms.dijkstraSnapshot(from: a.id, to: b.id, in: snapshot))
    }
}
