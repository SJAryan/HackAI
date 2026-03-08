import Foundation

struct DebriefReport: Identifiable, Codable {
    var id: String
    var sessionId: String
    var userId: String
    
    // Metrics analyzed by Gemini
    var communicationScore: Int
    var completionTimeSeconds: Int
    var conceptsMastered: [String]
    var areasForImprovement: [String]
    
    // Personalized Action Plan
    var visualMapNodes: [LearningNode]
}

struct LearningNode: Identifiable, Codable {
    var id: String
    var title: String
    var description: String
    var recommendedYoutubeUrl: String?
    var timestamp: String?
}
