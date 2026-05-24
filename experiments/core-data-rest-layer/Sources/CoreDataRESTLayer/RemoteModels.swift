import Foundation

public struct RemoteProject: Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var updatedAt: Date
    public var version: Int

    public init(id: UUID, name: String, updatedAt: Date, version: Int) {
        self.id = id
        self.name = name
        self.updatedAt = updatedAt
        self.version = version
    }
}

public struct RemoteTask: Codable, Equatable, Sendable {
    public var id: UUID
    public var projectId: UUID
    public var title: String
    public var status: String
    public var notes: String?
    public var updatedAt: Date
    public var version: Int
    public var isDetailLoaded: Bool

    public init(
        id: UUID,
        projectId: UUID,
        title: String,
        status: String,
        notes: String? = nil,
        updatedAt: Date,
        version: Int,
        isDetailLoaded: Bool = true
    ) {
        self.id = id
        self.projectId = projectId
        self.title = title
        self.status = status
        self.notes = notes
        self.updatedAt = updatedAt
        self.version = version
        self.isDetailLoaded = isDetailLoaded
    }

    public func summaryOnly() -> RemoteTask {
        RemoteTask(
            id: id,
            projectId: projectId,
            title: title,
            status: status,
            notes: nil,
            updatedAt: updatedAt,
            version: version,
            isDetailLoaded: false
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case projectId
        case title
        case status
        case notes
        case updatedAt
        case version
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        projectId = try container.decode(UUID.self, forKey: .projectId)
        title = try container.decode(String.self, forKey: .title)
        status = try container.decode(String.self, forKey: .status)
        isDetailLoaded = container.contains(.notes)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        version = try container.decode(Int.self, forKey: .version)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(projectId, forKey: .projectId)
        try container.encode(title, forKey: .title)
        try container.encode(status, forKey: .status)
        if isDetailLoaded {
            if let notes {
                try container.encode(notes, forKey: .notes)
            } else {
                try container.encodeNil(forKey: .notes)
            }
        }
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(version, forKey: .version)
    }
}

public struct TaskPatch: Codable, Equatable, Sendable {
    public var title: String
    public var status: String
    public var version: Int

    public init(title: String, status: String, version: Int) {
        self.title = title
        self.status = status
        self.version = version
    }
}

public struct CursorPage<Item: Codable & Equatable & Sendable>: Codable, Equatable, Sendable {
    public var items: [Item]
    public var nextCursor: String?

    public init(items: [Item], nextCursor: String?) {
        self.items = items
        self.nextCursor = nextCursor
    }
}

public struct NumberedPage<Item: Codable & Equatable & Sendable>: Codable, Equatable, Sendable {
    public var items: [Item]
    public var page: Int
    public var perPage: Int
    public var totalPages: Int?

    public init(items: [Item], page: Int, perPage: Int, totalPages: Int?) {
        self.items = items
        self.page = page
        self.perPage = perPage
        self.totalPages = totalPages
    }
}

public enum JSONCoding {
    public static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    public static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
