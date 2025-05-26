import Fluent
import Foundation
import OpenAPIRuntime
import OpenAPIVapor
import Vapor

struct Handler: APIProtocol {
  let app: Application

  var db: any Database {
    app.db
  }

  var user: User {
    get throws {
      guard let user = RequestMetadata.user else {
        throw Abort(.unauthorized)
      }

      return user
    }
  }
}
