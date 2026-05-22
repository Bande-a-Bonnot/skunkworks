import CoreData
import Foundation

@objc(GraphNode)
public final class GraphNode: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var label: String?
    @NSManaged public var outgoingEdges: Set<GraphEdge>
    @NSManaged public var incomingEdges: Set<GraphEdge>
}

@objc(GraphEdge)
public final class GraphEdge: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var kind: String?
    @NSManaged public var weight: Double
    @NSManaged public var source: GraphNode
    @NSManaged public var target: GraphNode
}

public extension GraphNode {
    var stableName: String {
        label ?? id.uuidString
    }
}

public extension GraphEdge {
    var stableSortKey: String {
        "\(target.stableName)|\(kind ?? "")|\(id.uuidString)"
    }
}
