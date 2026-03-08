import Foundation

struct UserDossier: Identifiable, Codable, Equatable {
    var id: String
    var currentSkills: [String]
    var futureInterests: [String]
    var suggestedRole: String
    var trackMastery: Int
    
    init(
        id: String = UUID().uuidString,
        currentSkills: [String] = [],
        futureInterests: [String] = [],
        suggestedRole: String = "",
        trackMastery: Int = 3
    ) {
        self.id = id
        self.currentSkills = currentSkills
        self.futureInterests = futureInterests
        self.suggestedRole = suggestedRole
        self.trackMastery = min(max(trackMastery, 1), 5)
    }
    
    var atlasSearchText: String {
        let skills = currentSkills.joined(separator: ", ")
        let interests = futureInterests.joined(separator: ", ")
        return "Current skills: \(skills). Future interests: \(interests). Suggested role: \(suggestedRole). Track mastery: \(trackMastery)/5."
    }
}
