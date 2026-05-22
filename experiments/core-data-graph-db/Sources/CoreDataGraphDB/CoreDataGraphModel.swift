import CoreData
import Foundation

public enum CoreDataGraphModel {
    public static let nodeEntityName = "GraphNode"
    public static let edgeEntityName = "GraphEdge"

    public static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let node = NSEntityDescription()
        node.name = nodeEntityName
        node.managedObjectClassName = NSStringFromClass(GraphNode.self)

        let edge = NSEntityDescription()
        edge.name = edgeEntityName
        edge.managedObjectClassName = NSStringFromClass(GraphEdge.self)

        let nodeID = attribute("id", type: .UUIDAttributeType, optional: false)
        let nodeLabel = attribute("label", type: .stringAttributeType, optional: true)
        node.properties = [nodeID, nodeLabel]

        let edgeID = attribute("id", type: .UUIDAttributeType, optional: false)
        let edgeKind = attribute("kind", type: .stringAttributeType, optional: true)
        let edgeWeight = attribute("weight", type: .doubleAttributeType, optional: false, defaultValue: 1.0)
        edge.properties = [edgeID, edgeKind, edgeWeight]

        let outgoing = relationship("outgoingEdges", destination: edge, min: 0, max: 0, deleteRule: .cascadeDeleteRule, optional: true)
        let incoming = relationship("incomingEdges", destination: edge, min: 0, max: 0, deleteRule: .cascadeDeleteRule, optional: true)
        let source = relationship("source", destination: node, min: 1, max: 1, deleteRule: .nullifyDeleteRule, optional: false)
        let target = relationship("target", destination: node, min: 1, max: 1, deleteRule: .nullifyDeleteRule, optional: false)

        outgoing.inverseRelationship = source
        source.inverseRelationship = outgoing
        incoming.inverseRelationship = target
        target.inverseRelationship = incoming

        node.properties += [outgoing, incoming]
        edge.properties += [source, target]

        model.entities = [node, edge]
        return model
    }

    private static func attribute(
        _ name: String,
        type: NSAttributeType,
        optional: Bool,
        defaultValue: Any? = nil
    ) -> NSAttributeDescription {
        let description = NSAttributeDescription()
        description.name = name
        description.attributeType = type
        description.isOptional = optional
        description.defaultValue = defaultValue
        return description
    }

    private static func relationship(
        _ name: String,
        destination: NSEntityDescription,
        min: Int,
        max: Int,
        deleteRule: NSDeleteRule,
        optional: Bool
    ) -> NSRelationshipDescription {
        let description = NSRelationshipDescription()
        description.name = name
        description.destinationEntity = destination
        description.minCount = min
        description.maxCount = max
        description.deleteRule = deleteRule
        description.isOptional = optional
        return description
    }
}
