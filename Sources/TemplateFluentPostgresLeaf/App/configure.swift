import Fluent
import FluentPostgresDriver
import Leaf
import NIOSSL
import OpenAPIRuntime
import OpenAPIVapor
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // Create a VaporTransport using the application.
    let transport = VaporTransport(routesBuilder: app.grouped(vaporMiddleware()))

    // Create an instance of your handler type that conforms the generated protocol
    // defining your service API.
    let handler = Handler(app: app)

    // Call the generated function on your implementation to add its request
    // handlers to the app.
    try handler.registerHandlers(
        on: transport,
        serverURL: Servers.Server1.url(),
        middlewares: apiMiddleware(app))

    app.databases.use(
        DatabaseConfigurationFactory.postgres(
            configuration: .init(
                hostname: Environment.get("DATABASE_HOST") ?? "localhost",
                port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:))
                    ?? SQLPostgresConfiguration.ianaPortNumber,
                username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
                password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
                database: Environment.get("DATABASE_NAME") ?? "vapor_database",
                tls: .prefer(try .init(configuration: .clientDefault)))
        ), as: .psql)

    addMigrations(app)

    app.views.use(.leaf)

    // register routes
    try routes(app)
}

private func addMigrations(_ app: Application) {
    app.migrations.add(CreateUser())
    app.migrations.add(CreateUserToken())
    app.migrations.add(CreateTodo())
}

private func vaporMiddleware() -> [any Middleware] {
    []
}

private func apiMiddleware(_ app: Application) -> [any ServerMiddleware] {
    [
        AuthMiddleware(app)
    ]
}
