import Foundation

struct User: Identifiable, Codable {
    var id: String
    var username: String
    var email: String
    var dateJoined: Date
}
