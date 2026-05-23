import Foundation

/// Wire-contract version, intentionally separate from per-resource optimistic concurrency versions.
public enum APIVersion: String, CaseIterable, Codable, Equatable, Sendable {
    case v1 = "1"
}

/// Local projection/schema version. This is the code-level stand-in for Core Data model versions
/// while the spike uses a programmatic model instead of checked-in `.xcdatamodeld` versions.
public struct LocalModelVersion: RawRepresentable, Codable, Equatable, Hashable, Sendable {
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let v1 = LocalModelVersion(rawValue: 1)
}

public struct APIModelVersionMapping: Equatable, Sendable {
    public var localModelVersion: LocalModelVersion
    public var readableAPIVersions: Set<APIVersion>
    public var writableAPIVersion: APIVersion

    public init(
        localModelVersion: LocalModelVersion,
        readableAPIVersions: Set<APIVersion>,
        writableAPIVersion: APIVersion
    ) {
        self.localModelVersion = localModelVersion
        self.readableAPIVersions = readableAPIVersions
        self.writableAPIVersion = writableAPIVersion
    }

    public func canRead(_ apiVersion: APIVersion) -> Bool {
        readableAPIVersions.contains(apiVersion)
    }

    public static let current = APIModelVersionMapping(
        localModelVersion: .v1,
        readableAPIVersions: [.v1],
        writableAPIVersion: .v1
    )
}
