import HTTPTypes
import OpenAPIRuntime
import Testing
import VaporTesting

@testable import TemplateFluentPostgresLeaf

@Suite("App Tests for Admin Routes", .serialized)
struct AuthMiddlewareTests {
  @Test("Open path with bearer token sets user")
  func openPathWithBearerTokenSetsUser() async throws {
    try await withConfiguredApp { app in
      let email = "test@example.com"
      let password = "testPassword1234"
      let (_, token) = try await Test.createUserWithToken(
        app: app, email: email, password: password)

      var headers = HTTPHeaders()
      headers.bearerAuthorization = BearerAuthorization(token: token)
      var request = HTTPRequest(method: .get, scheme: nil, authority: nil, path: "/api/users")
      request.headerFields = headers.httpFields
      let operationID = "testOperationID"

      try await _ = AuthMiddleware(app, openOperationIDs: [operationID]).intercept(
        request, body: nil, metadata: ServerRequestMetadata(),
        operationID: operationID,
        next: { _, _, _ in
          #expect(RequestMetadata.user != nil)
          return (HTTPResponse(status: .ok), nil)
        })
    }
  }

  @Test("Open path with bearer token sets user")
  func openPathWithBasicAuthSetsUser() async throws {
    try await withConfiguredApp { app in
      let email = "test@example.com"
      let password = "testPassword1234"
      let _ = try await Test.createUser(
        app: app, email: email, password: password)

      var headers = HTTPHeaders()
      headers.basicAuthorization = BasicAuthorization(username: email, password: password)
      var request = HTTPRequest(method: .get, scheme: nil, authority: nil, path: "/api/users")
      request.headerFields = headers.httpFields
      let operationID = "testOperationID"

      try await _ = AuthMiddleware(app, openOperationIDs: [operationID]).intercept(
        request, body: nil, metadata: ServerRequestMetadata(),
        operationID: operationID,
        next: { _, _, _ in
          #expect(RequestMetadata.user != nil)
          return (HTTPResponse(status: .ok), nil)
        })
    }
  }

  @Test("Open path with no auth does not set user")
  func openPathNoAuthThrowsError() async throws {
    try await withConfiguredApp { app in
      let request = HTTPRequest(method: .get, scheme: nil, authority: nil, path: "/api/users")
      let operationID = "testOperationID"
      try await _ = AuthMiddleware(app, openOperationIDs: [operationID]).intercept(
        request, body: nil, metadata: ServerRequestMetadata(),
        operationID: operationID,
        next: { _, _, _ in
          #expect(RequestMetadata.user == nil)
          return (HTTPResponse(status: .ok), nil)
        })
    }
  }

  @Test("Basic path with bearer token sets user")
  func basicPathWithBearerTokenSetsUser() async throws {
    try await withConfiguredApp { app in
      let email = "test@example.com"
      let password = "testPassword1234"
      let (_, token) = try await Test.createUserWithToken(
        app: app, email: email, password: password)

      var headers = HTTPHeaders()
      headers.bearerAuthorization = BearerAuthorization(token: token)
      var request = HTTPRequest(method: .get, scheme: nil, authority: nil, path: "/api/users")
      request.headerFields = headers.httpFields
      let operationID = "testOperationID"

      try await _ = AuthMiddleware(app, basicOperationIDs: [operationID]).intercept(
        request, body: nil, metadata: ServerRequestMetadata(),
        operationID: operationID,
        next: { _, _, _ in
          #expect(RequestMetadata.user != nil)
          return (HTTPResponse(status: .ok), nil)
        })
    }
  }

  @Test("Basic path with bearer token sets user")
  func basicPathWithBasicAuthSetsUser() async throws {
    try await withConfiguredApp { app in
      let email = "test@example.com"
      let password = "testPassword1234"
      let _ = try await Test.createUser(
        app: app, email: email, password: password)

      var headers = HTTPHeaders()
      headers.basicAuthorization = BasicAuthorization(username: email, password: password)
      var request = HTTPRequest(method: .get, scheme: nil, authority: nil, path: "/api/users")
      request.headerFields = headers.httpFields
      let operationID = "testOperationID"

      try await _ = AuthMiddleware(app, basicOperationIDs: [operationID]).intercept(
        request, body: nil, metadata: ServerRequestMetadata(),
        operationID: operationID,
        next: { _, _, _ in
          #expect(RequestMetadata.user != nil)
          return (HTTPResponse(status: .ok), nil)
        })
    }
  }

  @Test("Basic path with no auth throws unauthorized error")
  func basicPathNoAuthThrowsError() async throws {
    try await withConfiguredApp { app in
      let request = HTTPRequest(method: .get, scheme: nil, authority: nil, path: "/api/users")
      let operationID = "testOperationID"
      do {
        try await _ = AuthMiddleware(app, basicOperationIDs: [operationID]).intercept(
          request, body: nil, metadata: ServerRequestMetadata(),
          operationID: operationID,
          next: { _, _, _ in
            #expect(RequestMetadata.user != nil)
            return (HTTPResponse(status: .ok), nil)
          })
      } catch {
        #expect((error as? (any AbortError))?.status == .unauthorized)
      }
    }
  }

  @Test("Default path with bearer token sets user")
  func defaultPathWithBearerTokenSetsUser() async throws {
    try await withConfiguredApp { app in
      let email = "test@example.com"
      let password = "testPassword1234"
      let (_, token) = try await Test.createUserWithToken(
        app: app, email: email, password: password)

      var headers = HTTPHeaders()
      headers.bearerAuthorization = BearerAuthorization(token: token)
      var request = HTTPRequest(method: .get, scheme: nil, authority: nil, path: "/api/users")
      request.headerFields = headers.httpFields
      let operationID = "testOperationID"

      try await _ = AuthMiddleware(app).intercept(
        request, body: nil, metadata: ServerRequestMetadata(),
        operationID: operationID,
        next: { _, _, _ in
          #expect(RequestMetadata.user != nil)
          return (HTTPResponse(status: .ok), nil)
        })
    }
  }

  @Test("Default path with basic auth throws unauthorized error")
  func defaultPathWithBasicAuthThrowsError() async throws {
    try await withConfiguredApp { app in
      let email = "test@example.com"
      let password = "testPassword1234"
      let _ = try await Test.createUser(
        app: app, email: email, password: password)

      var headers = HTTPHeaders()
      headers.basicAuthorization = BasicAuthorization(username: email, password: password)
      var request = HTTPRequest(method: .get, scheme: nil, authority: nil, path: "/api/users")
      request.headerFields = headers.httpFields
      let operationID = "testOperationID"
      do {
        try await _ = AuthMiddleware(app).intercept(
          request, body: nil, metadata: ServerRequestMetadata(),
          operationID: operationID,
          next: { _, _, _ in
            #expect(RequestMetadata.user != nil)
            return (HTTPResponse(status: .ok), nil)
          })
      } catch {
        #expect((error as? (any AbortError))?.status == .unauthorized)
      }

    }
  }

  @Test("Default path with no auth throws unauthorized error")
  func defaultPathNoAuthThrowsError() async throws {
    try await withConfiguredApp { app in
      let request = HTTPRequest(method: .get, scheme: nil, authority: nil, path: "/api/users")
      let operationID = "testOperationID"
      do {
        try await _ = AuthMiddleware(app).intercept(
          request, body: nil, metadata: ServerRequestMetadata(),
          operationID: operationID,
          next: { _, _, _ in
            #expect(RequestMetadata.user != nil)
            return (HTTPResponse(status: .ok), nil)
          })
      } catch {
        #expect((error as? (any AbortError))?.status == .unauthorized)
      }
    }
  }
}
