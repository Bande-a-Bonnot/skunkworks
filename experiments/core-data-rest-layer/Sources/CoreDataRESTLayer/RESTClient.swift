import Foundation

public enum RESTClientError: Error, Equatable, CustomStringConvertible {
    case invalidResponse
    case httpStatus(Int, String)
    case conflict(remote: RemoteTask)

    public var description: String {
        switch self {
        case .invalidResponse:
            return "Invalid HTTP response"
        case let .httpStatus(status, body):
            return "HTTP \(status): \(body)"
        case let .conflict(remote):
            return "Conflict with remote task \(remote.id) at version \(remote.version)"
        }
    }
}

public enum TaskPaginationStrategy: Equatable, Sendable {
    case none
    case cursor(limit: Int)
    case offset(limit: Int)
    case numberedPages(perPage: Int)
}

public final class RESTClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let versionMapping: APIModelVersionMapping

    public init(
        baseURL: URL,
        session: URLSession = .shared,
        versionMapping: APIModelVersionMapping = .current
    ) {
        self.baseURL = baseURL
        self.session = session
        self.versionMapping = versionMapping
        self.decoder = JSONCoding.makeDecoder()
        self.encoder = JSONCoding.makeEncoder()
    }

    public func fetchProjects() async throws -> [RemoteProject] {
        try await send(path: "/projects", method: "GET", responseType: [RemoteProject].self)
    }

    public func fetchTasks(projectID: UUID, pageSize: Int? = nil) async throws -> [RemoteTask] {
        try await fetchTasks(
            projectID: projectID,
            pagination: pageSize.map { .cursor(limit: $0) } ?? .none
        )
    }

    public func fetchTasks(projectID: UUID, pagination: TaskPaginationStrategy) async throws -> [RemoteTask] {
        switch pagination {
        case .none:
            return try await send(path: "/projects/\(projectID.uuidString)/tasks", method: "GET", responseType: [RemoteTask].self)
        case let .cursor(limit):
            var allTasks: [RemoteTask] = []
            var cursor: String?
            repeat {
                let page = try await fetchTaskCursorPage(projectID: projectID, limit: limit, cursor: cursor)
                allTasks.append(contentsOf: page.items)
                cursor = page.nextCursor
            } while cursor != nil
            return allTasks
        case let .offset(limit):
            var allTasks: [RemoteTask] = []
            var offset = 0
            while true {
                let page = try await fetchTaskOffsetPage(projectID: projectID, limit: limit, offset: offset)
                allTasks.append(contentsOf: page)
                guard page.count == limit else { break }
                offset += page.count
            }
            return allTasks
        case let .numberedPages(perPage):
            var allTasks: [RemoteTask] = []
            var pageIndex = 1
            while true {
                let page = try await fetchTaskNumberedPage(projectID: projectID, page: pageIndex, perPage: perPage)
                allTasks.append(contentsOf: page.items)
                if let totalPages = page.totalPages {
                    guard page.page < totalPages else { break }
                } else {
                    guard page.items.count == perPage else { break }
                }
                pageIndex += 1
            }
            return allTasks
        }
    }

    public func fetchTaskCursorPage(projectID: UUID, limit: Int, cursor: String? = nil) async throws -> CursorPage<RemoteTask> {
        var components = URLComponents()
        components.path = "/projects/\(projectID.uuidString)/tasks"
        components.queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        if let cursor {
            components.queryItems?.append(URLQueryItem(name: "cursor", value: cursor))
        }
        guard let path = components.string else {
            throw RESTClientError.invalidResponse
        }
        return try await send(path: path, method: "GET", responseType: CursorPage<RemoteTask>.self)
    }

    public func fetchTaskOffsetPage(projectID: UUID, limit: Int, offset: Int) async throws -> [RemoteTask] {
        var components = URLComponents()
        components.path = "/projects/\(projectID.uuidString)/tasks"
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        guard let path = components.string else {
            throw RESTClientError.invalidResponse
        }
        return try await send(path: path, method: "GET", responseType: [RemoteTask].self)
    }

    public func fetchTaskNumberedPage(projectID: UUID, page: Int, perPage: Int) async throws -> NumberedPage<RemoteTask> {
        var components = URLComponents()
        components.path = "/projects/\(projectID.uuidString)/tasks"
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "perPage", value: String(perPage))
        ]
        guard let path = components.string else {
            throw RESTClientError.invalidResponse
        }
        return try await send(path: path, method: "GET", responseType: NumberedPage<RemoteTask>.self)
    }

    public func patchTask(id: UUID, title: String, status: String, version: Int) async throws -> RemoteTask {
        let patch = TaskPatch(title: title, status: status, version: version)
        return try await send(
            path: "/tasks/\(id.uuidString)",
            method: "PATCH",
            requestBody: patch,
            responseType: RemoteTask.self
        )
    }

    private func send<Response: Decodable>(
        path: String,
        method: String,
        responseType: Response.Type
    ) async throws -> Response {
        try await send(path: path, method: method, requestBody: Optional<TaskPatch>.none, responseType: responseType)
    }

    private func send<RequestBody: Encodable, Response: Decodable>(
        path: String,
        method: String,
        requestBody: RequestBody?,
        responseType: Response.Type
    ) async throws -> Response {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw RESTClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(versionMapping.writableAPIVersion.rawValue, forHTTPHeaderField: "X-API-Version")
        request.setValue(String(versionMapping.localModelVersion.rawValue), forHTTPHeaderField: "X-Local-Model-Version")

        if let requestBody {
            request.httpBody = try encoder.encode(requestBody)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RESTClientError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return try decoder.decode(Response.self, from: data)
        case 409:
            if let conflict = try? decoder.decode(ConflictResponse.self, from: data) {
                throw RESTClientError.conflict(remote: conflict.current)
            }
            fallthrough
        default:
            let body = String(data: data, encoding: .utf8) ?? ""
            throw RESTClientError.httpStatus(httpResponse.statusCode, body)
        }
    }
}

private struct ConflictResponse: Decodable {
    var error: String
    var current: RemoteTask
}
