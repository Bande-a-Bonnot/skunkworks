import CoreData
import Foundation

public enum GraphStoreError: Error, Equatable {
    case nodeNotFound(UUID)
    case nodeWithLabelNotFound(String)
}

public final class GraphStore {
    public let container: NSPersistentContainer

    public var context: NSManagedObjectContext {
        container.viewContext
    }

    public init(storeType: String = NSInMemoryStoreType) throws {
        container = NSPersistentContainer(name: "CoreDataGraphDB", managedObjectModel: CoreDataGraphModel.makeModel())
        let description = NSPersistentStoreDescription()
        description.type = storeType
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]

        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }
        if let loadError {
            throw loadError
        }

        context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        context.undoManager = nil
    }

    @discardableResult
    public func createNode(id: UUID = UUID(), label: String? = nil) -> GraphNode {
        let node = NSEntityDescription.insertNewObject(
            forEntityName: CoreDataGraphModel.nodeEntityName,
            into: context
        ) as! GraphNode
        node.id = id
        node.label = label
        return node
    }

    @discardableResult
    public func createEdge(
        id: UUID = UUID(),
        from source: GraphNode,
        to target: GraphNode,
        weight: Double = 1.0,
        kind: String? = nil
    ) -> GraphEdge {
        let edge = NSEntityDescription.insertNewObject(
            forEntityName: CoreDataGraphModel.edgeEntityName,
            into: context
        ) as! GraphEdge
        edge.id = id
        edge.source = source
        edge.target = target
        edge.weight = weight
        edge.kind = kind
        return edge
    }

    public func saveIfNeeded() throws {
        if context.hasChanges {
            try context.save()
        }
    }

    public func fetchNode(id: UUID) throws -> GraphNode? {
        let request = NSFetchRequest<GraphNode>(entityName: CoreDataGraphModel.nodeEntityName)
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    public func fetchNode(label: String) throws -> GraphNode? {
        let request = NSFetchRequest<GraphNode>(entityName: CoreDataGraphModel.nodeEntityName)
        request.predicate = NSPredicate(format: "label == %@", label)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    public func requireNode(label: String) throws -> GraphNode {
        if let node = try fetchNode(label: label) {
            return node
        }
        throw GraphStoreError.nodeWithLabelNotFound(label)
    }

    public func fetchNodes() throws -> [GraphNode] {
        let request = NSFetchRequest<GraphNode>(entityName: CoreDataGraphModel.nodeEntityName)
        request.sortDescriptors = [NSSortDescriptor(key: "label", ascending: true), NSSortDescriptor(key: "id", ascending: true)]
        return try context.fetch(request)
    }

    public func fetchEdges() throws -> [GraphEdge] {
        let request = NSFetchRequest<GraphEdge>(entityName: CoreDataGraphModel.edgeEntityName)
        request.sortDescriptors = [NSSortDescriptor(key: "weight", ascending: true), NSSortDescriptor(key: "id", ascending: true)]
        return try context.fetch(request)
    }

    @discardableResult
    public func seedDijkstraFixture() throws -> [String: GraphNode] {
        let a = createNode(label: "A")
        let b = createNode(label: "B")
        let c = createNode(label: "C")
        let d = createNode(label: "D")

        createEdge(from: a, to: b, weight: 4)
        createEdge(from: a, to: c, weight: 1)
        createEdge(from: c, to: b, weight: 2)
        createEdge(from: b, to: d, weight: 1)
        createEdge(from: c, to: d, weight: 5)

        try saveIfNeeded()
        return ["A": a, "B": b, "C": c, "D": d]
    }

    @discardableResult
    public func seedBFSFixture() throws -> [String: GraphNode] {
        let a = createNode(label: "A")
        let b = createNode(label: "B")
        let c = createNode(label: "C")
        let d = createNode(label: "D")
        let e = createNode(label: "E")

        createEdge(from: a, to: b)
        createEdge(from: a, to: c)
        createEdge(from: b, to: d)
        createEdge(from: c, to: d)
        createEdge(from: d, to: e)

        try saveIfNeeded()
        return ["A": a, "B": b, "C": c, "D": d, "E": e]
    }

    @discardableResult
    public func seedGrid(rows: Int, columns: Int) throws -> GridSeedResult {
        precondition(rows > 0)
        precondition(columns > 0)

        var nodes: [[GraphNode]] = []
        nodes.reserveCapacity(rows)

        for row in 0..<rows {
            var currentRow: [GraphNode] = []
            currentRow.reserveCapacity(columns)
            for column in 0..<columns {
                currentRow.append(createNode(label: "n\(row)_\(column)"))
            }
            nodes.append(currentRow)
        }

        for row in 0..<rows {
            for column in 0..<columns {
                let node = nodes[row][column]
                if column + 1 < columns {
                    createEdge(from: node, to: nodes[row][column + 1], weight: Double(((row + column) % 7) + 1))
                }
                if row + 1 < rows {
                    createEdge(from: node, to: nodes[row + 1][column], weight: Double(((row * 3 + column) % 11) + 1))
                }
            }
        }

        try saveIfNeeded()
        return GridSeedResult(
            start: nodes[0][0],
            target: nodes[rows - 1][columns - 1],
            nodeCount: rows * columns,
            edgeCount: rows * max(columns - 1, 0) + max(rows - 1, 0) * columns
        )
    }
}

public struct GridSeedResult {
    public let start: GraphNode
    public let target: GraphNode
    public let nodeCount: Int
    public let edgeCount: Int
}
