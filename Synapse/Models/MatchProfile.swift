import Foundation

struct MatchProfile: Identifiable, Codable {
    var id: String
    var userId: String
    var displayName: String
    var bio: String
    var skillsWordBank: [String]
    
    // This property will be populated by the backend after vectorizing the bio/skills
    var embedding: [Double]?
    
    // Identifies complementary attributes
    var primaryRole: RoleType
    
    enum RoleType: String, Codable {
        case technical
        case business
        case design
        case other
    }
}
