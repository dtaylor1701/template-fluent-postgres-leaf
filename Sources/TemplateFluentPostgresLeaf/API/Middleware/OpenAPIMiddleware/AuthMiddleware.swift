import FluentKit
import HTTPTypes
import OpenAPIRuntime
import Vapor

private enum AuthMiddlewareError: Error {
  case authNotFound
}

/// Middleware that authenticates requests based on the presence of a bearer token or basic auth credentials in the request headers.
struct AuthMiddleware: ServerMiddleware {
  /// The application to which this middleware applies.
  let app: Application

  /// The paths that do not require authentication.
  let openOperationIDs: Set<String>

  /// The paths that require basic authentication.
  let basicOperationIDs: Set<String>

  static let openOperationIDs: Set<String> = [
    Operations.CreateUser.id
  ]

  static let basicOperationIDs: Set<String> = [
    Operations.LoginUser.id
  ]

  /// Initializes a new instance of the `AuthMiddleware` class with the specified application and authentication paths. If a path is not
  /// included in the `openOperationIDs` or `basicOperationIDs` sets, it will be authenticated using bearer token scheme.
  /// - Parameters:
  ///   - app: The application to which this middleware applies.
  ///   - openOperationIDs: The paths that do not require authentication.
  ///   - basicOperationIDs: The paths that require basic authentication.
  init(
    _ app: Application,
    openOperationIDs: Set<String> = Self.openOperationIDs,
    basicOperationIDs: Set<String> = Self.basicOperationIDs
  ) {
    self.app = app
    self.openOperationIDs = openOperationIDs
    self.basicOperationIDs = basicOperationIDs
  }

  func intercept(
    _ request: HTTPTypes.HTTPRequest,
    body: OpenAPIRuntime.HTTPBody?,
    metadata: OpenAPIRuntime.ServerRequestMetadata,
    operationID: String,
    next: @Sendable (
      HTTPTypes.HTTPRequest, OpenAPIRuntime.HTTPBody?, OpenAPIRuntime.ServerRequestMetadata
    ) async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?)
  ) async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?) {

    // Try bearer auth first.
    do {
      let user = try await bearerAuthorization(for: request)
      return try await RequestMetadata.$user.withValue(user) {
        try await next(request, body, metadata)
      }
    } catch AuthMiddlewareError.authNotFound {
      guard openOperationIDs.union(basicOperationIDs).contains(operationID) else {
        throw Abort(.unauthorized)
      }
    }

    // Try basic auth next.
    do {
      let user = try await basicAuthorization(for: request)
      return try await RequestMetadata.$user.withValue(user) {
        try await next(request, body, metadata)
      }
    } catch AuthMiddlewareError.authNotFound {
      guard openOperationIDs.contains(operationID) else {
        throw Abort(.unauthorized)
      }
    }

    return try await next(request, body, metadata)
  }

  func bearerAuthorization(for request: HTTPTypes.HTTPRequest) async throws -> User {
    let headers = HTTPHeaders(request.headerFields)
    guard
      let tokenValue = headers.bearerAuthorization?.token
    else {
      throw AuthMiddlewareError.authNotFound
    }

    let token = try await UserToken.query(on: app.db)
      .filter(\.$value == tokenValue)
      .first()

    guard let token else {
      throw Abort(.unauthorized)
    }

    guard token.isValid else {
      try await token.delete(on: app.db)
      throw Abort(.unauthorized)
    }

    return try await token.$user.get(on: app.db)
  }

  func basicAuthorization(for request: HTTPTypes.HTTPRequest) async throws -> User {
    let headers = HTTPHeaders(request.headerFields)
    guard
      let username = headers.basicAuthorization?.username,
      let password = headers.basicAuthorization?.password
    else {
      throw AuthMiddlewareError.authNotFound
    }

    let user = try await User.query(on: app.db)
      .filter(\.$email == username)
      .first()

    guard let user else {
      throw Abort(.unauthorized)
    }

    guard try user.verify(password: password) else {
      throw Abort(.unauthorized)
    }

    return user
  }
}
