import Foundation

struct GameSession: Identifiable, Codable {
    var id: String
    var topic: String
    var playerAId: String // Controls
    var playerBId: String // Intel
    
    var startTime: Date
    var durationMinutes: Int = 15
    var isActive: Bool
    
    var currentLevel: Int
    var clues: [String]
    var expectedAnswer: String
    var peerMastery: Int?
    
    var timeRemaining: TimeInterval {
        let elapsed = Date().timeIntervalSince(startTime)
        let totalDuration = TimeInterval(durationMinutes * 60)
        return max(0, totalDuration - elapsed)
    }
}
