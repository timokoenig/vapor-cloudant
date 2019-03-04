import Vapor

public class CouchDBServiceMock: CouchDBService {
    
    public var error: Error?
    public var result: (Codable & CouchDBObject)?
    
    public init() {
        super.init(url: URL(string: "http://localhost")!, username: "", password: "")
    }
    
    public override func createDatabase(_ container: Container, databaseName: String) throws -> Future<Void> {
        let promise = container.eventLoop.newPromise(Void.self)
        if let error = self.error {
            promise.fail(error: error)
        } else {
            promise.succeed()
        }
        return promise.futureResult
    }
    
    public override func create<T: Codable & CouchDBObject>(_ container: Container, data: T, databaseName: String) throws -> Future<T> {
        let promise = container.eventLoop.newPromise(T.self)
        if let error = self.error {
            promise.fail(error: error)
        } else if let result = self.result {
            promise.succeed(result: result as! T)
        }
        return promise.futureResult
    }
    
    public override func getAll<T: Codable>(_ container: Container, databaseName: String, selector: [String: Any] = [:]) -> Future<[T]> {
        let promise = container.eventLoop.newPromise([T].self)
        if let error = self.error {
            promise.fail(error: error)
        } else if let result = self.result {
            promise.succeed(result: [result] as! [T])
        }
        return promise.futureResult
    }
    
    public override func get<T: Codable>(_ container: Container, identifier: String, databaseName: String) -> Future<T> {
        let promise = container.eventLoop.newPromise(T.self)
        if let error = self.error {
            promise.fail(error: error)
        } else if let result = self.result {
            promise.succeed(result: result as! T)
        }
        return promise.futureResult
    }
    
    public override func update<T: Codable & CouchDBObject>(_ container: Container, identifier: String, revision: String, data: T, databaseName: String) throws -> Future<T> {
        let promise = container.eventLoop.newPromise(T.self)
        if let error = self.error {
            promise.fail(error: error)
        } else if let result = self.result {
            promise.succeed(result: result as! T)
        }
        return promise.futureResult
    }
    
    public override func delete(_ container: Container, identifier: String, revision: String, databaseName: String) -> Future<Void> {
        let promise = container.eventLoop.newPromise(Void.self)
        if let error = self.error {
            promise.fail(error: error)
        } else {
            promise.succeed()
        }
        return promise.futureResult
    }
}
