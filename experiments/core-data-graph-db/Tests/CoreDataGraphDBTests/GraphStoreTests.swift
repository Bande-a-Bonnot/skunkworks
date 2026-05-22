import CoreData
import XCTest
@testable import CoreDataGraphDB

final class GraphStoreTests: XCTestCase {
    func testCreatesNodesAndFirstClassWeightedEdges() throws {
        let store = try GraphStore()
        let a = store.createNode(label: "A")
        let b = store.createNode(label: "B")
        let edge = store.createEdge(from: a, to: b, weight: 2.5, kind: "test")
        try store.saveIfNeeded()

        let nodes = try store.fetchNodes()
        let edges = try store.fetchEdges()

        XCTAssertEqual(nodes.map(\.label), ["A", "B"])
        XCTAssertEqual(edges.count, 1)
        XCTAssertEqual(edges.first?.id, edge.id)
        XCTAssertEqual(edges.first?.source.id, a.id)
        XCTAssertEqual(edges.first?.target.id, b.id)
        XCTAssertEqual(edges.first?.weight, 2.5)
        XCTAssertEqual(edges.first?.kind, "test")
        XCTAssertEqual(a.outgoingEdges.first?.id, edge.id)
        XCTAssertEqual(b.incomingEdges.first?.id, edge.id)
    }

    func testGridSeedCreatesExpectedCounts() throws {
        let store = try GraphStore()
        let grid = try store.seedGrid(rows: 3, columns: 4)

        XCTAssertEqual(grid.nodeCount, 12)
        XCTAssertEqual(grid.edgeCount, 17)
        XCTAssertEqual(try store.fetchNodes().count, 12)
        XCTAssertEqual(try store.fetchEdges().count, 17)
        XCTAssertEqual(grid.start.label, "n0_0")
        XCTAssertEqual(grid.target.label, "n2_3")
    }
}
