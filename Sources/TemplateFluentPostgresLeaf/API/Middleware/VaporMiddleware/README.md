Vapor middleware includes the context of the Vapor.Request and its conveniences. It's tempting to 
try to pass state from the vapor world into the OpenAPI world, but because SwiftNIO and swift concurrency
use a different global executor (theory) getting TaskLocal state to work proved challenging. 

Examples attempt:
```
import Vapor

struct RequestInjectionMiddleware: AsyncMiddleware {
  func respond(
    to request: Request,
    chainingTo responder: any AsyncResponder
  ) async throws -> Response {
    try await RequestMetadata.$request.withValue(request) {
      try await responder.respond(to: request)
    }
  }
}

```
