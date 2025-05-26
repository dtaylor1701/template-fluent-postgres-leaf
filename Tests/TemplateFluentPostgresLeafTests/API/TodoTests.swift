import Fluent
import OpenAPIRuntime
import OpenAPIVapor
import Testing
import VaporTesting

@testable import TemplateFluentPostgresLeaf

@Suite("App Tests for Todo Routes", .serialized)
struct TodoTests {
  @Test("Getting all of a user's Todos")
  func getAllTodos() async throws {
    try await withConfiguredApp { app in
      let (user, token) = try await Test.createUserWithToken(app: app)
      let otherUser = try await Test.createUser(
        app: app, email: "other@example.com", password: "someOtherPassword")

      let userTodos = try await Test.createTodos(app: app, forUser: user, count: 5)
      let otherUserTodos = try await Test.createTodos(app: app, forUser: otherUser, count: 3)

      try await app.testing().test(
        .GET, "api/todos",
        beforeRequest: { req in
          req.withAuthToken(token)
        },
        afterResponse: { res in
          #expect(res.status == .ok)
          // let todosResponse = try res.content .content.decode([Components.Schemas.Todo.self])
          let todosResponse = try JSONDecoder().decode(
            [Components.Schemas.Todo].self, from: res.body
          )
          #expect(todosResponse.count == userTodos.count)
          let userTodosIDs = try Set<String>(
            userTodos.map { try $0.requireID().uuidString }
          )
          let otherUserTodosIDs = try Set<String>(
            otherUserTodos.map { try $0.requireID().uuidString }
          )
          let responseTodosIDs = Set<String>(
            todosResponse.map { $0.id ?? "" }
          )
          #expect(userTodosIDs == responseTodosIDs)
          #expect(responseTodosIDs.isDisjoint(with: otherUserTodosIDs))
        }
      )
    }
  }

  @Test("Creating a Todo")
  func createTodo() async throws {
    try await withConfiguredApp { app in
      let (user, token) = try await Test.createUserWithToken(app: app)

      let newTodo = Components.Schemas.Todo(title: "Some test")
      let request = Operations.CreateTodo.Input(body: .json(newTodo))

      var todoID = UUID().uuidString

      try await app.testing().test(
        .POST, "api/todos",
        beforeRequest: { req in
          req.withAuthToken(token)
          try req.hydrate(with: request)
        },
        afterResponse: { res in
          #expect(res.status == .created)
          let newTodo = try res.content.decode(Components.Schemas.Todo.self)
          #expect(newTodo.title == newTodo.title)
          todoID = try #require(newTodo.id)
        }
      )

      let userTodos = try await user.$todos.query(on: app.db).all()
      #expect(userTodos.count == 1)
      let userTodosID = try userTodos.first?.requireID().uuidString
      #expect(userTodosID == todoID)
    }
  }

  @Test("Deleting a Todo")
  func deleteTodo() async throws {
    try await withConfiguredApp { app in

      let (user, token) = try await Test.createUserWithToken(app: app)
      let todos = try await Test.createTodos(app: app, forUser: user, count: 2)
      let toDelete = try #require(todos.first)
      let toRemain = try #require(todos.last)

      try await app.testing().test(
        .DELETE, "api/todos/\(toDelete.requireID())",
        beforeRequest: { req in
          req.withAuthToken(token)
        },
        afterResponse: { res async throws in
          #expect(res.status == .noContent)
          let model = try await Todo.find(toDelete.id, on: app.db)
          #expect(model == nil)
          let remaining = try await user.$todos.query(on: app.db).all()
          #expect(remaining.count == 1)
          let remainingTodo = try #require(remaining.first)
          let remainingTodoID = try remainingTodo.requireID()
          let toRemainTodoID = try toRemain.requireID()
          #expect(remainingTodoID == toRemainTodoID)
        })
    }
  }
}
