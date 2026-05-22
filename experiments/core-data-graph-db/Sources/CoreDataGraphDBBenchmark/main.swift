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

struct BenchmarkResult {
    let store: StoreKind
    let benchmarkCase: BenchmarkCase
    let nodeCount: Int
    let edgeCount: Int
    let seedMilliseconds: Double
    let snapshotMilliseconds: Double
    let managedBFSMilliseconds: Double
    let snapshotBFSMilliseconds: Double
    let managedDijkstraMilliseconds: Double
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

func printCSV(_ results: [BenchmarkResult]) {
    print("store,case,nodes,edges,seed_ms,snapshot_ms,managed_bfs_ms,snapshot_bfs_ms,managed_dijkstra_ms,snapshot_dijkstra_ms,path_weight")
    for result in results {
        print([
            result.store.rawValue,
            result.benchmarkCase.name,
            String(result.nodeCount),
            String(result.edgeCount),
            format(result.seedMilliseconds),
            format(result.snapshotMilliseconds),
            format(result.managedBFSMilliseconds),
            format(result.snapshotBFSMilliseconds),
            format(result.managedDijkstraMilliseconds),
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
        "Snapshot ms",
        "BFS managed ms",
        "BFS snapshot ms",
        "Dijkstra managed ms",
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
            format(result.managedBFSMilliseconds),
            format(result.snapshotBFSMilliseconds),
            format(result.managedDijkstraMilliseconds),
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

        precondition(managedBFS.value.count == seed.value.nodeCount)
        precondition(snapshotBFS.value.count == seed.value.nodeCount)
        precondition(managedDijkstra.value != nil)
        precondition(snapshotDijkstra.value != nil)
        precondition(managedDijkstra.value?.totalWeight == snapshotDijkstra.value?.totalWeight)

        results.append(BenchmarkResult(
            store: storeKind,
            benchmarkCase: benchmark,
            nodeCount: seed.value.nodeCount,
            edgeCount: seed.value.edgeCount,
            seedMilliseconds: seed.milliseconds,
            snapshotMilliseconds: snapshot.milliseconds,
            managedBFSMilliseconds: managedBFS.milliseconds,
            snapshotBFSMilliseconds: snapshotBFS.milliseconds,
            managedDijkstraMilliseconds: managedDijkstra.milliseconds,
            snapshotDijkstraMilliseconds: snapshotDijkstra.milliseconds,
            pathWeight: pathWeight
        ))
    }
}

print("CoreDataGraphDB benchmark")
print("Stores: \(stores.map(\.rawValue).joined(separator: ", "))")
print("Graph: directed weighted grid, right/down edges")
print("Context reset after seeding: yes")
print("Format: \(outputFormat.rawValue)")
print("")

switch outputFormat {
case .table:
    printTable(results)
case .csv:
    printCSV(results)
}
