import CoreDataGraphDB
import Foundation

struct BenchmarkCase {
    let name: String
    let rows: Int
    let columns: Int
}

struct Timed<Value> {
    let value: Value
    let milliseconds: Double
}

@discardableResult
func measure<Value>(_ block: () throws -> Value) rethrows -> Timed<Value> {
    let start = DispatchTime.now().uptimeNanoseconds
    let value = try block()
    let end = DispatchTime.now().uptimeNanoseconds
    return Timed(value: value, milliseconds: Double(end - start) / 1_000_000)
}

func format(_ value: Double) -> String {
    String(format: "%.3f", value)
}

let cases = [
    BenchmarkCase(name: "small", rows: 10, columns: 10),
    BenchmarkCase(name: "medium", rows: 25, columns: 25),
    BenchmarkCase(name: "large", rows: 50, columns: 50),
]

print("CoreDataGraphDB benchmark")
print("Store: NSInMemoryStoreType")
print("Graph: directed weighted grid, right/down edges")
print("")
print("case,nodes,edges,snapshot_ms,managed_bfs_ms,snapshot_bfs_ms,managed_dijkstra_ms,snapshot_dijkstra_ms,path_weight")

for benchmark in cases {
    let store = try GraphStore()
    let seed = try store.seedGrid(rows: benchmark.rows, columns: benchmark.columns)

    let snapshot = try measure {
        try GraphAlgorithms.makeSnapshot(context: store.context)
    }

    let managedBFS = measure {
        GraphAlgorithms.breadthFirstManaged(from: seed.start)
    }

    let snapshotBFS = measure {
        GraphAlgorithms.breadthFirstSnapshot(from: seed.start.id, in: snapshot.value)
    }

    let managedDijkstra = measure {
        GraphAlgorithms.dijkstraManaged(from: seed.start, to: seed.target)
    }

    let snapshotDijkstra = measure {
        GraphAlgorithms.dijkstraSnapshot(from: seed.start.id, to: seed.target.id, in: snapshot.value)
    }

    let pathWeight = snapshotDijkstra.value?.totalWeight ?? .nan

    print([
        benchmark.name,
        String(seed.nodeCount),
        String(seed.edgeCount),
        format(snapshot.milliseconds),
        format(managedBFS.milliseconds),
        format(snapshotBFS.milliseconds),
        format(managedDijkstra.milliseconds),
        format(snapshotDijkstra.milliseconds),
        format(pathWeight),
    ].joined(separator: ","))

    precondition(managedBFS.value.count == seed.nodeCount)
    precondition(snapshotBFS.value.count == seed.nodeCount)
    precondition(managedDijkstra.value != nil)
    precondition(snapshotDijkstra.value != nil)
    precondition(managedDijkstra.value?.totalWeight == snapshotDijkstra.value?.totalWeight)
}
