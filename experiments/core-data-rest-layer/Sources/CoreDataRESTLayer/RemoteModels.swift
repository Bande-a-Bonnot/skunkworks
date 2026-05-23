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
    public var updatedAt: Date
    public var version: Int

    public init(id: UUID, projectId: UUID, title: String, status: String, updatedAt: Date, version: Int) {
        self.id = id
        self.projectId = projectId
        self.title = title
        self.status = status
        self.updatedAt = updatedAt
        self.version = version
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
