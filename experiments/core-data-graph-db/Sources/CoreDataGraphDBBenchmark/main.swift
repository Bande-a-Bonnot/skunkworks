import CoreData
import CoreDataGraphDB
import Foundation

struct BenchmarkCase {
    let name: String
    let rows: Int
    let columns: Int
}

enum StoreKind: String, CaseIterable {
    case inMemory = "in-memory"
    case sqlite

    var coreDataStoreType: String {
        switch self {
        case .inMemory: NSInMemoryStoreType
        case .sqlite: NSSQLiteStoreType
        }
    }
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

func selectedStores(arguments: [String]) -> [StoreKind] {
    guard let storeFlagIndex = arguments.firstIndex(of: "--store"), arguments.indices.contains(storeFlagIndex + 1) else {
        return StoreKind.allCases
    }

    switch arguments[storeFlagIndex + 1] {
    case "in-memory": return [.inMemory]
    case "sqlite": return [.sqlite]
    case "both": return StoreKind.allCases
    default:
        fputs("Usage: CoreDataGraphDBBenchmark [--store in-memory|sqlite|both]\n", stderr)
        exit(2)
    }
}

func temporarySQLiteURL(caseName: String) throws -> URL {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("CoreDataGraphDBBenchmark-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory.appendingPathComponent("\(caseName).sqlite")
}

func cleanupSQLiteArtifacts(for sqliteURL: URL?) {
    guard let sqliteURL else { return }
    let directory = sqliteURL.deletingLastPathComponent()
    try? FileManager.default.removeItem(at: directory)
}

let cases = [
    BenchmarkCase(name: "small", rows: 10, columns: 10),
    BenchmarkCase(name: "medium", rows: 25, columns: 25),
    BenchmarkCase(name: "large", rows: 50, columns: 50),
]

let stores = selectedStores(arguments: CommandLine.arguments)

print("CoreDataGraphDB benchmark")
print("Stores: \(stores.map(\.rawValue).joined(separator: ", "))")
print("Graph: directed weighted grid, right/down edges")
print("Context reset after seeding: yes")
print("")
print("store,case,nodes,edges,seed_ms,snapshot_ms,managed_bfs_ms,snapshot_bfs_ms,managed_dijkstra_ms,snapshot_dijkstra_ms,path_weight")

for storeKind in stores {
    for benchmark in cases {
        let sqliteURL = storeKind == .sqlite ? try temporarySQLiteURL(caseName: benchmark.name) : nil
        defer { cleanupSQLiteArtifacts(for: sqliteURL) }

        let store = try GraphStore(storeType: storeKind.coreDataStoreType, storeURL: sqliteURL)
        let seed = try measure {
            try store.seedGrid(rows: benchmark.rows, columns: benchmark.columns)
        }

        let startLabel = seed.value.start.label!
        let targetLabel = seed.value.target.label!
        store.context.reset()
        let start = try store.requireNode(label: startLabel)
        let target = try store.requireNode(label: targetLabel)

        let snapshot = try measure {
            try GraphAlgorithms.makeSnapshot(context: store.context)
        }

        let managedBFS = measure {
            GraphAlgorithms.breadthFirstManaged(from: start)
        }

        let snapshotBFS = measure {
            GraphAlgorithms.breadthFirstSnapshot(from: start.id, in: snapshot.value)
        }

        let managedDijkstra = measure {
            GraphAlgorithms.dijkstraManaged(from: start, to: target)
        }

        let snapshotDijkstra = measure {
            GraphAlgorithms.dijkstraSnapshot(from: start.id, to: target.id, in: snapshot.value)
        }

        let pathWeight = snapshotDijkstra.value?.totalWeight ?? .nan

        print([
            storeKind.rawValue,
            benchmark.name,
            String(seed.value.nodeCount),
            String(seed.value.edgeCount),
            format(seed.milliseconds),
            format(snapshot.milliseconds),
            format(managedBFS.milliseconds),
            format(snapshotBFS.milliseconds),
            format(managedDijkstra.milliseconds),
            format(snapshotDijkstra.milliseconds),
            format(pathWeight),
        ].joined(separator: ","))

        precondition(managedBFS.value.count == seed.value.nodeCount)
        precondition(snapshotBFS.value.count == seed.value.nodeCount)
        precondition(managedDijkstra.value != nil)
        precondition(snapshotDijkstra.value != nil)
        precondition(managedDijkstra.value?.totalWeight == snapshotDijkstra.value?.totalWeight)
    }
}
