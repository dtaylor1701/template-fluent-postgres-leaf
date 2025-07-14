import Fluent
import OpenAPIRuntime
import OpenAPIVapor
import Testing
import VaporTesting

@testable import TemplateFluentPostgresLeaf

@Suite("App Tests for Auth Routes", .serialized)
struct AuthTests {
  @Test("Create user")
  func createUser() async throws {
    try await withConfiguredApp { app in
      let email = "test@example.com"
      let password = "testPassword1234"

      let body = Components.Schemas.NewUser(email: email, password: password)
      let request = Operations.CreateUser.Input(
        body: .json(body))
      try await app.testing().test(
        .POST, "/api/users",
        beforeRequest: { req in
          try req.hydrate(with: request)
        },
        afterResponse: { res async in
          #expect(res.status == .created)
          let responseToken = try? JSONDecoder().decode(
            Components.Schemas.UserToken.self, from: res.body
          )
          .value
          #expect(responseToken?.isEmpty == false)
          do {
            let savedToken = try await UserToken.query(on: app.db)
              .filter(\.$value == (responseToken ?? ""))
              .first()
            #expect(savedToken != nil)
          } catch {
            #expect(Bool(false), "Failed to retrieve token from database.")
          }
        })
    }
  }

  @Test("Login")
  func login() async throws {
    try await withConfiguredApp { app in
      let email = "test@example.com"
      let password = "testPassword1234"

      let newUser = try User(email: email, passwordHash: Bcrypt.hash(password))
      try await newUser.save(on: app.db)

      let body = Components.Schemas.LoginRequest(email: email, password: password)
      let request = Operations.LoginUser.Input(
        body: .json(body))
      var headers = HTTPHeaders()
      headers.basicAuthorization = BasicAuthorization(username: email, password: password)

      try await app.testing().test(
        .POST, "/api/login",
        beforeRequest: { req in
          req.headers = headers
          try req.hydrate(with: request)
        },
        afterResponse: { res async in
          #expect(res.status == .created)
          let responseToken = try? JSONDecoder().decode(
            Components.Schemas.UserToken.self, from: res.body
          )
          .value
          #expect(responseToken?.isEmpty == false)
        })
    }
  }
}
