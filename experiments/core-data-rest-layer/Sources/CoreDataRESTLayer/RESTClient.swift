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

public final class RESTClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONCoding.makeDecoder()
        self.encoder = JSONCoding.makeEncoder()
    }

    public func fetchProjects() async throws -> [RemoteProject] {
        try await send(path: "/projects", method: "GET", responseType: [RemoteProject].self)
    }

    public func fetchTasks(projectID: UUID) async throws -> [RemoteTask] {
        try await send(path: "/projects/\(projectID.uuidString)/tasks", method: "GET", responseType: [RemoteTask].self)
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
