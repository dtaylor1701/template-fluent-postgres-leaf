import Fluent

struct CreateUserToken: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("user_tokens")
            .id()
            .field("value", .string, .required)
            .field("user_id", .uuid, .required, .references("users", "id"))
            .field("expires_at", .date)
            .unique(on: "value")
            .create()
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("user_tokens").delete()
    }
}
