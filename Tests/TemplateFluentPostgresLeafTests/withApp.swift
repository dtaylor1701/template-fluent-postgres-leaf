import Fluent
import FluentSQLiteDriver
import OpenAPIRuntime
import OpenAPIVapor
import Testing
import VaporTesting

@testable import TemplateFluentPostgresLeaf

func withConfiguredApp(_ test: (Application) async throws -> Void) async throws {
  let app = try await Application.make(.testing)

  app.databases.use(.sqlite(.memory), as: .sqlite)
  do {
    try await configure(app)
    try await app.autoMigrate()
    try await test(app)
    try await app.autoRevert()
  } catch {
    try? await app.autoRevert()
    try await app.asyncShutdown()
    throw error
  }
  try await app.asyncShutdown()
}
