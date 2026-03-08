import Foundation

enum OperativeRole: String, Codable, CaseIterable {
    case controls = "Controls"
    case intel = "Intel"
}

enum MissionOutcome: String, Codable {
    case pending
    case success
    case failed
    case abandoned
}

struct GameSession: Identifiable, Codable {
    var sessionId: String
    var playerA_Id: String
    var playerB_Id: String
    var trackTopic: String
    var isComplete: Bool
    
    var missionBrief: String
    var clues: [String]
    var expectedAnswer: String
    var localAssignedRole: OperativeRole
    var startedAt: Date
    var durationSeconds: Int
    var outcome: MissionOutcome
    var aiHintLog: [String]
    var peerMastery: Int?
    var peerSuggestedRole: String?
    var peerSummary: String?
    var matchScore: Double?
    
    var id: String { sessionId }
    
    var timeRemaining: Int {
        let elapsed = Int(Date().timeIntervalSince(startedAt))
        return max(0, durationSeconds - elapsed)
    }
    
    // Compatibility aliases for older screens still in the project.
    var topic: String {
        get { trackTopic }
        set { trackTopic = newValue }
    }
    
    var playerAId: String {
        get { playerA_Id }
        set { playerA_Id = newValue }
    }
    
    var playerBId: String {
        get { playerB_Id }
        set { playerB_Id = newValue }
    }
    
    var startTime: Date {
        get { startedAt }
        set { startedAt = newValue }
    }
    
    var durationMinutes: Int {
        get { max(1, durationSeconds / 60) }
        set { durationSeconds = max(60, newValue * 60) }
    }
    
    var isActive: Bool {
        !isComplete
    }
    
    var currentLevel: Int {
        get { 1 }
        set { }
    }
    
    init(
        sessionId: String = UUID().uuidString,
        playerA_Id: String,
        playerB_Id: String,
        trackTopic: String,
        isComplete: Bool = false,
        missionBrief: String = "",
        clues: [String] = [],
        expectedAnswer: String = "",
        localAssignedRole: OperativeRole = .controls,
        startedAt: Date = Date(),
        durationSeconds: Int = 900,
        outcome: MissionOutcome = .pending,
        aiHintLog: [String] = [],
        peerMastery: Int? = nil,
        peerSuggestedRole: String? = nil,
        peerSummary: String? = nil,
        matchScore: Double? = nil
    ) {
        self.sessionId = sessionId
        self.playerA_Id = playerA_Id
        self.playerB_Id = playerB_Id
        self.trackTopic = trackTopic
        self.isComplete = isComplete
        self.missionBrief = missionBrief
        self.clues = clues
        self.expectedAnswer = expectedAnswer
        self.localAssignedRole = localAssignedRole
        self.startedAt = startedAt
        self.durationSeconds = durationSeconds
        self.outcome = outcome
        self.aiHintLog = aiHintLog
        self.peerMastery = peerMastery
        self.peerSuggestedRole = peerSuggestedRole
        self.peerSummary = peerSummary
        self.matchScore = matchScore
    }
    
    init(
        id: String,
        topic: String,
        playerAId: String,
        playerBId: String,
        startTime: Date,
        isActive: Bool,
        currentLevel: Int,
        clues: [String],
        expectedAnswer: String,
        peerMastery: Int?
    ) {
        self.init(
            sessionId: id,
            playerA_Id: playerAId,
            playerB_Id: playerBId,
            trackTopic: topic,
            isComplete: !isActive,
            missionBrief: "",
            clues: clues,
            expectedAnswer: expectedAnswer,
            localAssignedRole: .controls,
            startedAt: startTime,
            durationSeconds: 900,
            outcome: .pending,
            aiHintLog: [],
            peerMastery: peerMastery,
            peerSuggestedRole: nil,
            peerSummary: nil,
            matchScore: nil
        )
    }
}
