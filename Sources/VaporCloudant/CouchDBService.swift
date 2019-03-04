import Vapor
import SwiftCloudant

public protocol CouchDBObject {
    var id: String? { get set }
    var revision: String? { get set }
}

public class CouchDBService: Service {

    private let client: CouchDBClient
    public var jsonEncoder = JSONEncoder()
    public var jsonDecoder = JSONDecoder()

    public init(url: URL, username: String, password: String) {
        client = CouchDBClient(url: url, username: username, password: password)

        // Set custom json date encoding/decoding strategy (Format is specified by ISO-8601: yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        jsonEncoder.dateEncodingStrategy = .formatted(dateFormatter)
        jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
    }

    /// Create a database
    public func createDatabase(_ container: Container, databaseName: String) throws -> Future<Void> {
        let promise = container.eventLoop.newPromise(Void.self)
        let create = CreateDatabaseOperation(name: databaseName) { (response, httpInfo, error) in
            if let error = error {
                promise.fail(error: self.transform(error))
                return
            }
            promise.succeed()
        }
        client.add(operation:create)

        return promise.futureResult
    }

    /// Create a document
    public func create<T: Codable & CouchDBObject>(_ container: Container, data: T, databaseName: String) throws -> Future<T> {
        let jsonObject = try jsonEncoder.encode(data)
        guard let json = try JSONSerialization.jsonObject(with: jsonObject, options: []) as? [String: Any] else {
            throw Abort(.badRequest, reason: "Unable to serialize json dictionary")
        }

        let promise = container.eventLoop.newPromise(T.self)
        let read = PutDocumentOperation(id: UUID().uuidString, body: json, databaseName: databaseName) { (response, httpInfo, error) in
            if let error = error {
                promise.fail(error: self.transform(error))
                return
            }
            let responseCode = response?["ok"] as? Int
            if responseCode != 1 {
                promise.fail(error: Abort(HTTPResponseStatus.badRequest, reason: "Unable to create object"))
                return
            }

            var data = data
            data.id = response?["id"] as? String
            data.revision = response?["rev"] as? String
            promise.succeed(result: data)
        }
        client.add(operation:read)

        return promise.futureResult
    }

    /// Get all documents
    public func getAll<T: Codable>(_ container: Container, databaseName: String, selector: [String: Any] = [:]) -> Future<[T]> {
        let promise = container.eventLoop.newPromise([T].self)

        let operation = FindDocumentsOperation(selector: selector, databaseName: databaseName) { (response, httpInfo, error) in
            if let error = error {
                promise.fail(error: self.transform(error))
                return
            }
            do {
                let documents = response?["docs"] as? [[String: Any]]
                let responseJson = try JSONSerialization.data(withJSONObject: documents ?? [], options: [])
                promise.succeed(result: try self.jsonDecoder.decode([T].self, from: responseJson))
            } catch {
                promise.fail(error: error)
            }
        }
        client.add(operation: operation)

        return promise.futureResult
    }

    /// Get a document
    public func get<T: Codable>(_ container: Container, identifier: String, databaseName: String) -> Future<T> {
        let promise = container.eventLoop.newPromise(T.self)
        let read = GetDocumentOperation(id: identifier, databaseName: databaseName) { (response, httpInfo, error) in
            if let error = error {
                promise.fail(error: self.transform(error))
                return
            }
            do {
                let responseJson = try JSONSerialization.data(withJSONObject: response ?? [:], options: [])
                promise.succeed(result: try self.jsonDecoder.decode(T.self, from: responseJson))
            } catch {
                promise.fail(error: error)
            }
        }
        client.add(operation:read)

        return promise.futureResult
    }

    /// Update a document
    public func update<T: Codable & CouchDBObject>(_ container: Container, identifier: String, revision: String, data: T, databaseName: String) throws -> Future<T> {
        let jsonObject = try jsonEncoder.encode(data)
        guard let json = try JSONSerialization.jsonObject(with: jsonObject, options: []) as? [String: Any] else {
            throw Abort(.badRequest, reason: "Unable to serialize json dictionary")
        }

        let promise = container.eventLoop.newPromise(T.self)
        let read = PutDocumentOperation(id: identifier, revision: revision, body: json, databaseName: databaseName) { (response, httpInfo, error) in
            if let error = error {
                promise.fail(error: self.transform(error))
                return
            }
            let responseCode = response?["ok"] as? Int
            if responseCode != 1 {
                promise.fail(error: Abort(HTTPResponseStatus.badRequest, reason: "Unable to update object"))
                return
            }

            var data = data
            data.id = response?["id"] as? String
            data.revision = response?["rev"] as? String
            promise.succeed(result: data)
        }
        client.add(operation:read)

        return promise.futureResult
    }

    /// Delete a document
    public func delete(_ container: Container, identifier: String, revision: String, databaseName: String) -> Future<Void> {
        let promise = container.eventLoop.newPromise(Void.self)
        let read = DeleteDocumentOperation(id: identifier, revision: revision, databaseName: databaseName) { (response, httpInfo, error) in
            if let error = error {
                promise.fail(error: self.transform(error))
            } else {
                promise.succeed()
            }
        }
        client.add(operation:read)

        return promise.futureResult
    }

    /// Transform SwiftCloudant error to Vapor error so it can be handled correctly
    private func transform(_ error: Error) -> Error {
         switch error as? SwiftCloudant.Operation.Error {
         case .http(let statusCode, let response)?:
             return Abort(.init(statusCode: statusCode), reason: response ?? "Unknown SwiftCloudant error")
         case .unexpectedJSONFormat(let statusCode, let response)?:
             return Abort(.init(statusCode: statusCode), reason: response ?? "SwiftCloudant unexpected JSON format")
         default:
             return error
         }
    }
}
