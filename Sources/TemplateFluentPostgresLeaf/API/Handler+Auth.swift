import Fluent
import Foundation
import OpenAPIRuntime
import OpenAPIVapor
import Vapor

extension Handler {
  func loginUser(_ input: Operations.LoginUser.Input) async throws -> Operations.LoginUser.Output {
    let token = try user.generateToken()
    try await token.save(on: db)
    return .created(.init(body: .json(.init(value: token.value))))
  }

  func createUser(_ input: Operations.CreateUser.Input) async throws -> Operations.CreateUser.Output
  {
    guard case let .json(user) = input.body else {
      throw Abort(.badRequest)
    }

    let newUser = try User(email: user.email, passwordHash: Bcrypt.hash(user.password))
    try await newUser.save(on: db)

    let token = try newUser.generateToken()
    try await token.save(on: db)
    return .created(.init(body: .json(.init(value: token.value))))
  }
}
