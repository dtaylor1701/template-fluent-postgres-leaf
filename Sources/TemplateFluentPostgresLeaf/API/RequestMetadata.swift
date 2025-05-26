import Vapor

enum RequestMetadata {
  @TaskLocal
  static var user: User?
}
