import Fluent
import Foundation
import OpenAPIRuntime
import OpenAPIVapor
import Vapor

extension Handler {

  func deleteTodo(_ input: Operations.DeleteTodo.Input) async throws -> Operations.DeleteTodo.Output
  {
    guard let id = UUID(uuidString: input.path.id) else {
      throw Abort(.badRequest)
    }

    guard let todo = try await Todo.find(id, on: db) else {
      throw Abort(.notFound)
    }

    let todoUser: User = try await todo.$user.get(on: db)

    guard try todoUser.requireID() == user.requireID() else {
      throw Abort(.forbidden)
    }

    try await todo.delete(on: db)
    return .noContent(.init())
  }

  func createTodo(_ input: Operations.CreateTodo.Input) async throws -> Operations.CreateTodo.Output
  {
    guard case let .json(todo) = input.body else {
      throw Abort(.badRequest)
    }

    let newTodo = try Todo(title: todo.title, userID: user.requireID())
    try await newTodo.save(on: db)

    let responseTodo = Components.Schemas.Todo(id: newTodo.id?.uuidString, title: newTodo.title)

    return .created(.init(body: .json(responseTodo)))
  }

  func getTodos(_ input: Operations.GetTodos.Input) async throws -> Operations.GetTodos.Output {
    let todos = try await user.$todos.query(on: db).all()

    let responseTodos: [Components.Schemas.Todo] = todos.map {
      .init(id: $0.id?.uuidString, title: $0.title)
    }

    return .ok(.init(body: .json(responseTodos)))
  }
}
