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

enum OutputFormat: String {
    case table
    case csv
}

struct Timed<Value> {
    let value: Value
    let milliseconds: Double
}

struct ManagedEndpoints {
    let start: GraphNode
    let target: GraphNode
}

struct BenchmarkResult {
    let store: StoreKind
    let benchmarkCase: BenchmarkCase
    let nodeCount: Int
    let edgeCount: Int
    let seedMilliseconds: Double
    let snapshotMilliseconds: Double
    let prefetchMilliseconds: Double
    let managedBFSMilliseconds: Double
    let prefetchedBFSMilliseconds: Double
    let snapshotBFSMilliseconds: Double
    let managedDijkstraMilliseconds: Double
    let prefetchedDijkstraMilliseconds: Double
    let snapshotDijkstraMilliseconds: Double
    let pathWeight: Double
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

func usageAndExit() -> Never {
    fputs("Usage: CoreDataGraphDBBenchmark [--store in-memory|sqlite|both] [--format table|csv]\n", stderr)
    exit(2)
}

func value(after flag: String, in arguments: [String]) -> String? {
    guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
        return nil
    }
    return arguments[index + 1]
}

func selectedStores(arguments: [String]) -> [StoreKind] {
    guard let store = value(after: "--store", in: arguments) else {
        return StoreKind.allCases
    }

    switch store {
    case "in-memory": return [.inMemory]
    case "sqlite": return [.sqlite]
    case "both": return StoreKind.allCases
    default: usageAndExit()
    }
}

func selectedOutputFormat(arguments: [String]) -> OutputFormat {
    guard let format = value(after: "--format", in: arguments) else {
        return .table
    }

    guard let outputFormat = OutputFormat(rawValue: format) else {
        usageAndExit()
    }
    return outputFormat
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

func endpoints(in store: GraphStore, startLabel: String, targetLabel: String) throws -> ManagedEndpoints {
    ManagedEndpoints(
        start: try store.requireNode(label: startLabel),
        target: try store.requireNode(label: targetLabel)
    )
}

func prefetchOutgoingGraph(in context: NSManagedObjectContext) throws {
    let request = NSFetchRequest<GraphNode>(entityName: CoreDataGraphModel.nodeEntityName)
    request.relationshipKeyPathsForPrefetching = ["outgoingEdges", "outgoingEdges.target"]
    request.sortDescriptors = [NSSortDescriptor(key: "label", ascending: true)]
    _ = try context.fetch(request)
}

func printCSV(_ results: [BenchmarkResult]) {
    print("store,case,nodes,edges,seed_ms,snapshot_ms,prefetch_ms,managed_bfs_ms,prefetched_bfs_ms,snapshot_bfs_ms,managed_dijkstra_ms,prefetched_dijkstra_ms,snapshot_dijkstra_ms,path_weight")
    for result in results {
        print([
            result.store.rawValue,
            result.benchmarkCase.name,
            String(result.nodeCount),
            String(result.edgeCount),
            format(result.seedMilliseconds),
            format(result.snapshotMilliseconds),
            format(result.prefetchMilliseconds),
            format(result.managedBFSMilliseconds),
            format(result.prefetchedBFSMilliseconds),
            format(result.snapshotBFSMilliseconds),
            format(result.managedDijkstraMilliseconds),
            format(result.prefetchedDijkstraMilliseconds),
            format(result.snapshotDijkstraMilliseconds),
            format(result.pathWeight),
        ].joined(separator: ","))
    }
}

func printTable(_ results: [BenchmarkResult]) {
    let headers = [
        "Store",
        "Case",
        "Nodes",
        "Edges",
        "Seed ms",
        "Snapshot build ms",
        "Prefetch ms",
        "BFS managed ms",
        "BFS prefetched ms",
        "BFS snapshot ms",
        "Dijkstra managed ms",
        "Dijkstra prefetched ms",
        "Dijkstra snapshot ms",
        "Path weight",
    ]
    let rows = results.map { result in
        [
            result.store.rawValue,
            result.benchmarkCase.name,
            String(result.nodeCount),
            String(result.edgeCount),
            format(result.seedMilliseconds),
            format(result.snapshotMilliseconds),
            format(result.prefetchMilliseconds),
            format(result.managedBFSMilliseconds),
            format(result.prefetchedBFSMilliseconds),
            format(result.snapshotBFSMilliseconds),
            format(result.managedDijkstraMilliseconds),
            format(result.prefetchedDijkstraMilliseconds),
            format(result.snapshotDijkstraMilliseconds),
            format(result.pathWeight),
        ]
    }
    let widths = headers.indices.map { index in
        ([headers[index]] + rows.map { $0[index] }).map(\.count).max() ?? 0
    }
    let rightAligned = Set(2..<headers.count)

    func cell(_ value: String, at index: Int) -> String {
        if rightAligned.contains(index) {
            return String(repeating: " ", count: widths[index] - value.count) + value
        }
        return value + String(repeating: " ", count: widths[index] - value.count)
    }

    func line(_ values: [String]) -> String {
        "| " + values.enumerated().map { cell($0.element, at: $0.offset) }.joined(separator: " | ") + " |"
    }

    let separator = "| " + widths.enumerated().map { index, width in
        rightAligned.contains(index)
            ? String(repeating: "-", count: max(width - 1, 0)) + ":"
            : String(repeating: "-", count: width)
    }.joined(separator: " | ") + " |"

    print(line(headers))
    print(separator)
    for row in rows {
        print(line(row))
    }
}

let cases = [
    BenchmarkCase(name: "small", rows: 10, columns: 10),
    BenchmarkCase(name: "medium", rows: 25, columns: 25),
    BenchmarkCase(name: "large", rows: 50, columns: 50),
]

let stores = selectedStores(arguments: CommandLine.arguments)
let outputFormat = selectedOutputFormat(arguments: CommandLine.arguments)
var results: [BenchmarkResult] = []
results.reserveCapacity(stores.count * cases.count)

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
        let managedBFSEndpoints = try endpoints(in: store, startLabel: startLabel, targetLabel: targetLabel)
        let managedBFS = measure {
            GraphAlgorithms.breadthFirstManaged(from: managedBFSEndpoints.start)
        }

        store.context.reset()
        let managedDijkstraEndpoints = try endpoints(in: store, startLabel: startLabel, targetLabel: targetLabel)
        let managedDijkstra = measure {
            GraphAlgorithms.dijkstraManaged(from: managedDijkstraEndpoints.start, to: managedDijkstraEndpoints.target)
        }

        store.context.reset()
        let prefetch = try measure {
            try prefetchOutgoingGraph(in: store.context)
            return try endpoints(in: store, startLabel: startLabel, targetLabel: targetLabel)
        }
        let prefetchedBFS = measure {
            GraphAlgorithms.breadthFirstManaged(from: prefetch.value.start)
        }
        let prefetchedDijkstra = measure {
            GraphAlgorithms.dijkstraManaged(from: prefetch.value.start, to: prefetch.value.target)
        }

        store.context.reset()
        let snapshot = try measure {
            try GraphAlgorithms.makeSnapshot(context: store.context)
        }
        let snapshotEndpoints = try endpoints(in: store, startLabel: startLabel, targetLabel: targetLabel)
        let snapshotBFS = measure {
            GraphAlgorithms.breadthFirstSnapshot(from: snapshotEndpoints.start.id, in: snapshot.value)
        }
        let snapshotDijkstra = measure {
            GraphAlgorithms.dijkstraSnapshot(from: snapshotEndpoints.start.id, to: snapshotEndpoints.target.id, in: snapshot.value)
        }

        let pathWeight = snapshotDijkstra.value?.totalWeight ?? .nan

        precondition(managedBFS.value.count == seed.value.nodeCount)
        precondition(prefetchedBFS.value.count == seed.value.nodeCount)
        precondition(snapshotBFS.value.count == seed.value.nodeCount)
        precondition(managedDijkstra.value != nil)
        precondition(prefetchedDijkstra.value != nil)
        precondition(snapshotDijkstra.value != nil)
        precondition(managedDijkstra.value?.totalWeight == snapshotDijkstra.value?.totalWeight)
        precondition(prefetchedDijkstra.value?.totalWeight == snapshotDijkstra.value?.totalWeight)

        results.append(BenchmarkResult(
            store: storeKind,
            benchmarkCase: benchmark,
            nodeCount: seed.value.nodeCount,
            edgeCount: seed.value.edgeCount,
            seedMilliseconds: seed.milliseconds,
            snapshotMilliseconds: snapshot.milliseconds,
            prefetchMilliseconds: prefetch.milliseconds,
            managedBFSMilliseconds: managedBFS.milliseconds,
            prefetchedBFSMilliseconds: prefetchedBFS.milliseconds,
            snapshotBFSMilliseconds: snapshotBFS.milliseconds,
            managedDijkstraMilliseconds: managedDijkstra.milliseconds,
            prefetchedDijkstraMilliseconds: prefetchedDijkstra.milliseconds,
            snapshotDijkstraMilliseconds: snapshotDijkstra.milliseconds,
            pathWeight: pathWeight
        ))
    }
}

print("CoreDataGraphDB benchmark")
print("Stores: \(stores.map(\.rawValue).joined(separator: ", "))")
print("Graph: directed weighted grid, right/down edges")
print("Context reset before each strategy: yes")
print("Prefetch: outgoingEdges + outgoingEdges.target")
print("Format: \(outputFormat.rawValue)")
print("")

switch outputFormat {
case .table:
    printTable(results)
case .csv:
    printCSV(results)
}
