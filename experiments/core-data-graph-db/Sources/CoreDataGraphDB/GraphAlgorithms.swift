import CoreData
import Foundation

public struct ShortestPath: Equatable {
    public let nodeIDs: [UUID]
    public let totalWeight: Double

    public init(nodeIDs: [UUID], totalWeight: Double) {
        self.nodeIDs = nodeIDs
        self.totalWeight = totalWeight
    }
}

public struct SnapshotEdge: Equatable {
    public let target: UUID
    public let weight: Double
    public let kind: String?

    public init(target: UUID, weight: Double, kind: String?) {
        self.target = target
        self.weight = weight
        self.kind = kind
    }
}

public struct GraphSnapshot {
    public let labelsByID: [UUID: String]
    public let adjacency: [UUID: [SnapshotEdge]]

    public init(labelsByID: [UUID: String], adjacency: [UUID: [SnapshotEdge]]) {
        self.labelsByID = labelsByID
        self.adjacency = adjacency
    }

    public func label(for id: UUID) -> String {
        labelsByID[id] ?? id.uuidString
    }
}

public enum GraphAlgorithms {
    public static func makeSnapshot(context: NSManagedObjectContext) throws -> GraphSnapshot {
        let nodeRequest = NSFetchRequest<GraphNode>(entityName: CoreDataGraphModel.nodeEntityName)
        let nodes = try context.fetch(nodeRequest)

        let edgeRequest = NSFetchRequest<GraphEdge>(entityName: CoreDataGraphModel.edgeEntityName)
        let edges = try context.fetch(edgeRequest)

        var labelsByID: [UUID: String] = [:]
        labelsByID.reserveCapacity(nodes.count)
        for node in nodes {
            labelsByID[node.id] = node.stableName
        }

        var adjacency: [UUID: [SnapshotEdge]] = [:]
        adjacency.reserveCapacity(nodes.count)
        for node in nodes {
            adjacency[node.id] = []
        }
        for edge in edges {
            adjacency[edge.source.id, default: []].append(
                SnapshotEdge(target: edge.target.id, weight: edge.weight, kind: edge.kind)
            )
        }

        for source in adjacency.keys {
            adjacency[source]?.sort { lhs, rhs in
                let leftKey = "\(labelsByID[lhs.target] ?? lhs.target.uuidString)|\(lhs.kind ?? "")|\(lhs.weight)"
                let rightKey = "\(labelsByID[rhs.target] ?? rhs.target.uuidString)|\(rhs.kind ?? "")|\(rhs.weight)"
                return leftKey < rightKey
            }
        }

        return GraphSnapshot(labelsByID: labelsByID, adjacency: adjacency)
    }

    public static func breadthFirstManaged(from start: GraphNode) -> [UUID] {
        var visited = Set<UUID>()
        var order: [UUID] = []
        var queue: [GraphNode] = [start]
        var readIndex = 0

        while readIndex < queue.count {
            let node = queue[readIndex]
            readIndex += 1

            guard visited.insert(node.id).inserted else { continue }
            order.append(node.id)

            let outgoing = node.outgoingEdges.sorted { $0.stableSortKey < $1.stableSortKey }
            for edge in outgoing where !visited.contains(edge.target.id) {
                queue.append(edge.target)
            }
        }

        return order
    }

    public static func breadthFirstSnapshot(from start: UUID, in snapshot: GraphSnapshot) -> [UUID] {
        var visited = Set<UUID>()
        var order: [UUID] = []
        var queue: [UUID] = [start]
        var readIndex = 0

        while readIndex < queue.count {
            let node = queue[readIndex]
            readIndex += 1

            guard visited.insert(node).inserted else { continue }
            order.append(node)

            for edge in snapshot.adjacency[node] ?? [] where !visited.contains(edge.target) {
                queue.append(edge.target)
            }
        }

        return order
    }

    public static func dijkstraManaged(from start: GraphNode, to target: GraphNode) -> ShortestPath? {
        var distances: [UUID: Double] = [start.id: 0]
        var previous: [UUID: UUID] = [:]
        var visited = Set<UUID>()
        var frontier: [UUID: GraphNode] = [start.id: start]

        while let currentID = frontier.keys.min(by: { (distances[$0] ?? .infinity) < (distances[$1] ?? .infinity) }) {
            guard let current = frontier.removeValue(forKey: currentID) else { continue }
            guard visited.insert(current.id).inserted else { continue }

            if current.id == target.id {
                return ShortestPath(nodeIDs: reconstructPath(to: target.id, previous: previous), totalWeight: distances[target.id] ?? 0)
            }

            let currentDistance = distances[current.id] ?? .infinity
            for edge in current.outgoingEdges.sorted(by: { $0.stableSortKey < $1.stableSortKey }) where !visited.contains(edge.target.id) {
                let candidate = currentDistance + edge.weight
                if candidate < (distances[edge.target.id] ?? .infinity) {
                    distances[edge.target.id] = candidate
                    previous[edge.target.id] = current.id
                    frontier[edge.target.id] = edge.target
                }
            }
        }

        return nil
    }

    public static func dijkstraSnapshot(from start: UUID, to target: UUID, in snapshot: GraphSnapshot) -> ShortestPath? {
        dijkstra(
            start: start,
            target: target,
            neighbors: { nodeID in
                (snapshot.adjacency[nodeID] ?? []).map { ($0.target, $0.weight) }
            }
        )
    }

    private static func dijkstra(
        start: UUID,
        target: UUID,
        neighbors: (UUID) -> [(UUID, Double)]
    ) -> ShortestPath? {
        var distances: [UUID: Double] = [start: 0]
        var previous: [UUID: UUID] = [:]
        var visited = Set<UUID>()
        var frontier = Set<UUID>([start])

        while let current = frontier.min(by: { (distances[$0] ?? .infinity) < (distances[$1] ?? .infinity) }) {
            frontier.remove(current)
            guard visited.insert(current).inserted else { continue }

            if current == target {
                return ShortestPath(nodeIDs: reconstructPath(to: target, previous: previous), totalWeight: distances[target] ?? 0)
            }

            let currentDistance = distances[current] ?? .infinity
            for (neighbor, weight) in neighbors(current) where !visited.contains(neighbor) {
                let candidate = currentDistance + weight
                if candidate < (distances[neighbor] ?? .infinity) {
                    distances[neighbor] = candidate
                    previous[neighbor] = current
                    frontier.insert(neighbor)
                }
            }
        }

        return nil
    }

    private static func reconstructPath(to target: UUID, previous: [UUID: UUID]) -> [UUID] {
        var path = [target]
        var current = target
        while let prior = previous[current] {
            path.append(prior)
            current = prior
        }
        return path.reversed()
    }
}
