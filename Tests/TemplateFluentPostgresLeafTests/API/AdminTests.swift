import Testing
import VaporTesting

@testable import TemplateFluentPostgresLeaf

@Suite("App Tests for Admin Routes", .serialized)
struct AdminTests {
  @Test("Test Hello World Route")
  func helloWorld() async throws {
    try await withConfiguredApp { app -> Void in
      try await app.testing().test(
        .GET, "hello",
        afterResponse: { res async in
          #expect(res.status == .ok)
          #expect(res.body.string == "Hello, world!")
        })
    }
  }
}
