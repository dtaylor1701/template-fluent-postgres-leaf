import Fluent
import FluentSQLiteDriver
import HTTPTypes
import NIOCore
import NIOPosix
import OpenAPIRuntime
import OpenAPIVapor
import Testing
import VaporTesting

@testable import TemplateFluentPostgresLeaf

enum Test {
  static func createUserWithToken(
    app: Application,
    email: String = "test@example.com", password: String = "testPassword1234"
  ) async throws -> (User, String) {
    let newUser = try await createUser(app: app)

    let token = try newUser.generateToken()
    try await token.save(on: app.db)

    return (newUser, token.value)
  }

  static func createUser(
    app: Application, email: String = "test@example.com", password: String = "testPassword1234"
  ) async throws -> User {
    let newUser = try User(email: email, passwordHash: Bcrypt.hash(password))
    try await newUser.save(on: app.db)
    return newUser
  }

  static func createTodos(app: Application, forUser user: User, count: UInt) async throws -> [Todo]
  {
    let userID = try user.requireID()
    var todos: [Todo] = []
    for i in 0..<count {
      let todo = Todo(title: "Todo \(i)", userID: userID)
      try await todo.save(on: app.db)
      todos.append(todo)
    }
    return todos
  }
}

extension TestingHTTPRequest {
  mutating func hydrate(with hydrating: any TestingHTTPRequestHydrating) throws {
    try hydrating.hydrate(&self)
  }

  mutating func withAuthToken(_ token: String) {
    headers.bearerAuthorization = BearerAuthorization(token: token)
  }
}

protocol TestingHTTPRequestHydrating {
  func hydrate(_ request: inout TestingHTTPRequest) throws
}

extension Operations.CreateUser.Input: TestingHTTPRequestHydrating {
  func hydrate(_ request: inout TestingHTTPRequest) throws {
    if case .json(let body) = body {
      try request.content.encode(body, as: .json)
    }
  }
}

extension Operations.LoginUser.Input: TestingHTTPRequestHydrating {
  func hydrate(_ request: inout TestingHTTPRequest) throws {
    if case .json(let body) = body {
      try request.content.encode(body, as: .json)
    }
  }
}

extension Operations.CreateTodo.Input: TestingHTTPRequestHydrating {
  func hydrate(_ request: inout TestingHTTPRequest) throws {
    if case .json(let body) = body {
      try request.content.encode(body, as: .json)
    }
  }
}

extension HTTPHeaders {
  var httpFields: HTTPFields {
    let fields: [HTTPField] = compactMap { name, value in
      guard let name = HTTPField.Name(name) else { return nil }

      return HTTPField(name: name, value: value)
    }

    return HTTPFields(fields)
  }
}
