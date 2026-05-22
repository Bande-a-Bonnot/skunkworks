import CoreDataRESTLayer
import Foundation
import Network

public enum EmbeddedRESTServerError: Error, CustomStringConvertible {
    case failedToStart
    case notStarted
    case unknownTask(UUID)

    public var description: String {
        switch self {
        case .failedToStart:
            return "Embedded REST server failed to start"
        case .notStarted:
            return "Embedded REST server has not started"
        case let .unknownTask(id):
            return "Unknown task \(id)"
        }
    }
}

public final class EmbeddedRESTServer {
    private let queue = DispatchQueue(label: "EmbeddedRESTServer.listener")
    private let stateQueue = DispatchQueue(label: "EmbeddedRESTServer.state")
    private var listener: NWListener?
    private var assignedPort: UInt16?
    private var projects: [UUID: RemoteProject]
    private var tasks: [UUID: RemoteTask]
    private let encoder = JSONCoding.makeEncoder()
    private let decoder = JSONCoding.makeDecoder()

    public init(projects: [RemoteProject], tasks: [RemoteTask]) {
        self.projects = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0) })
        self.tasks = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })
    }

    public var baseURL: URL {
        get throws {
            guard let assignedPort else {
                throw EmbeddedRESTServerError.notStarted
            }
            return URL(string: "http://127.0.0.1:\(assignedPort)")!
        }
    }

    public func start(timeout: TimeInterval = 5) throws {
        let listener = try NWListener(using: .tcp, on: 0)
        listener.newConnectionHandler = { [weak self] connection in
            self?.handle(connection: connection)
        }

        let semaphore = DispatchSemaphore(value: 0)
        var startError: Error?
        listener.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.assignedPort = listener.port?.rawValue
                semaphore.signal()
            case .failed(let error):
                startError = error
                semaphore.signal()
            default:
                break
            }
        }

        self.listener = listener
        listener.start(queue: queue)

        if semaphore.wait(timeout: .now() + timeout) == .timedOut {
            throw EmbeddedRESTServerError.failedToStart
        }
        if let startError {
            throw startError
        }
        guard assignedPort != nil else {
            throw EmbeddedRESTServerError.failedToStart
        }
    }

    public func stop() {
        listener?.cancel()
        listener = nil
        assignedPort = nil
    }

    @discardableResult
    public func mutateTask(id: UUID, mutate: (inout RemoteTask) -> Void) throws -> RemoteTask {
        try stateQueue.sync {
            guard var task = tasks[id] else {
                throw EmbeddedRESTServerError.unknownTask(id)
            }
            mutate(&task)
            tasks[id] = task
            return task
        }
    }

    public func currentTask(id: UUID) throws -> RemoteTask {
        try stateQueue.sync {
            guard let task = tasks[id] else {
                throw EmbeddedRESTServerError.unknownTask(id)
            }
            return task
        }
    }

    private func handle(connection: NWConnection) {
        connection.start(queue: queue)
        receive(on: connection, buffer: Data())
    }

    private func receive(on connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            if let error {
                self.send(response: .text(status: 500, body: error.localizedDescription), on: connection)
                return
            }

            var nextBuffer = buffer
            if let data {
                nextBuffer.append(data)
            }

            if let request = HTTPRequest(data: nextBuffer) {
                self.respond(to: request, on: connection)
            } else if isComplete {
                self.send(response: .text(status: 400, body: "Incomplete HTTP request"), on: connection)
            } else {
                self.receive(on: connection, buffer: nextBuffer)
            }
        }
    }

    private func respond(to request: HTTPRequest, on connection: NWConnection) {
        do {
            let response = try route(request)
            send(response: response, on: connection)
        } catch {
            send(response: .text(status: 500, body: String(describing: error)), on: connection)
        }
    }

    private func route(_ request: HTTPRequest) throws -> HTTPResponse {
        let path = request.path.split(separator: "/").map(String.init)

        if request.method == "GET", path == ["projects"] {
            let payload = stateQueue.sync {
                projects.values.sorted { $0.name < $1.name }
            }
            return try .json(status: 200, body: payload, encoder: encoder)
        }

        if request.method == "GET",
           path.count == 3,
           path[0] == "projects",
           path[2] == "tasks",
           let projectID = UUID(uuidString: path[1]) {
            let payload = stateQueue.sync {
                tasks.values
                    .filter { $0.projectId == projectID }
                    .sorted { $0.title < $1.title }
            }
            return try .json(status: 200, body: payload, encoder: encoder)
        }

        if request.method == "PATCH",
           path.count == 2,
           path[0] == "tasks",
           let taskID = UUID(uuidString: path[1]) {
            let patch = try decoder.decode(TaskPatch.self, from: request.body)
            return try patchTask(id: taskID, patch: patch)
        }

        return .text(status: 404, body: "No route for \(request.method) \(request.path)")
    }

    private func patchTask(id: UUID, patch: TaskPatch) throws -> HTTPResponse {
        try stateQueue.sync {
            guard var task = tasks[id] else {
                return .text(status: 404, body: "No task \(id)")
            }

            guard patch.version == task.version else {
                return try .json(
                    status: 409,
                    body: ConflictResponse(error: "conflict", current: task),
                    encoder: encoder
                )
            }

            task.title = patch.title
            task.status = patch.status
            task.version += 1
            task.updatedAt = Date(timeIntervalSince1970: floor(Date().timeIntervalSince1970))
            tasks[id] = task
            return try .json(status: 200, body: task, encoder: encoder)
        }
    }

    private func send(response: HTTPResponse, on connection: NWConnection) {
        connection.send(content: response.data, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}

private struct ConflictResponse: Codable {
    var error: String
    var current: RemoteTask
}

private struct HTTPRequest {
    var method: String
    var path: String
    var body: Data

    init?(data: Data) {
        guard let headerRange = data.range(of: Data("\r\n\r\n".utf8)) else {
            return nil
        }

        let headerData = data[..<headerRange.lowerBound]
        guard let headerText = String(data: headerData, encoding: .utf8) else {
            return nil
        }

        let lines = headerText.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            return nil
        }
        let requestParts = requestLine.split(separator: " ", maxSplits: 2).map(String.init)
        guard requestParts.count >= 2 else {
            return nil
        }

        var contentLength = 0
        for line in lines.dropFirst() {
            let pieces = line.split(separator: ":", maxSplits: 1).map(String.init)
            guard pieces.count == 2 else { continue }
            if pieces[0].lowercased() == "content-length" {
                contentLength = Int(pieces[1].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            }
        }

        let bodyStart = headerRange.upperBound
        guard data.count >= bodyStart + contentLength else {
            return nil
        }

        method = requestParts[0]
        path = requestParts[1].components(separatedBy: "?").first ?? requestParts[1]
        body = Data(data[bodyStart..<(bodyStart + contentLength)])
    }
}

private struct HTTPResponse {
    var status: Int
    var contentType: String
    var body: Data

    var data: Data {
        var header = "HTTP/1.1 \(status) \(reasonPhrase(for: status))\r\n"
        header += "Content-Type: \(contentType)\r\n"
        header += "Content-Length: \(body.count)\r\n"
        header += "Connection: close\r\n"
        header += "\r\n"
        var response = Data(header.utf8)
        response.append(body)
        return response
    }

    static func json<Body: Encodable>(status: Int, body: Body, encoder: JSONEncoder) throws -> HTTPResponse {
        HTTPResponse(status: status, contentType: "application/json", body: try encoder.encode(body))
    }

    static func text(status: Int, body: String) -> HTTPResponse {
        HTTPResponse(status: status, contentType: "text/plain; charset=utf-8", body: Data(body.utf8))
    }

    private func reasonPhrase(for status: Int) -> String {
        switch status {
        case 200: return "OK"
        case 400: return "Bad Request"
        case 404: return "Not Found"
        case 409: return "Conflict"
        case 500: return "Internal Server Error"
        default: return "HTTP Status"
        }
    }
}
