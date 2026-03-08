import Foundation

struct DebriefReport: Identifiable, Codable {
    var id: String
    var sessionId: String?
    var userId: String?
    var communicationScore: Int?
    var completionTimeSeconds: Int?
    var conceptsMastered: [String]
    var areasForImprovement: [String]
    var nextSteps: [String]
    var recommendedVideoLinks: [String]
    var visualMapNodes: [LearningNode]
    var dallasVisualPrompt: String?
    
    init(
        id: String = UUID().uuidString,
        sessionId: String? = nil,
        userId: String? = nil,
        communicationScore: Int? = nil,
        completionTimeSeconds: Int? = nil,
        conceptsMastered: [String] = [],
        areasForImprovement: [String] = [],
        nextSteps: [String] = [],
        recommendedVideoLinks: [String] = [],
        visualMapNodes: [LearningNode] = [],
        dallasVisualPrompt: String? = nil
    ) {
        self.id = id
        self.sessionId = sessionId
        self.userId = userId
        self.communicationScore = communicationScore
        self.completionTimeSeconds = completionTimeSeconds
        self.conceptsMastered = conceptsMastered
        self.areasForImprovement = areasForImprovement
        self.nextSteps = nextSteps
        self.recommendedVideoLinks = recommendedVideoLinks
        self.visualMapNodes = visualMapNodes
        self.dallasVisualPrompt = dallasVisualPrompt
    }
}

struct LearningNode: Identifiable, Codable {
    var id: String
    var title: String
    var description: String
    var recommendedYoutubeUrl: String?
    var timestamp: String?
    
    init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        recommendedYoutubeUrl: String? = nil,
        timestamp: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.recommendedYoutubeUrl = recommendedYoutubeUrl
        self.timestamp = timestamp
    }
}
