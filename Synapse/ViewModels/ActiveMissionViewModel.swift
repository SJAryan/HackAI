import Foundation
import Combine

@MainActor
final class ActiveMissionViewModel: ObservableObject {
    @Published var session: GameSession
    @Published var isPlayerA: Bool = true
    @Published var revealedCluesCount: Int = 1
    @Published var answerInput: String = ""
    @Published var isMissionComplete: Bool = false
    @Published var hintMessage: String = ""
    @Published var missionStatusLine: String = "VOICE LINK STANDBY"
    
    private var cancellables = Set<AnyCancellable>()
    
    init(session: GameSession) {
        self.session = session
        self.isPlayerA = session.localAssignedRole == .controls
        self.missionStatusLine = AppRuntime.isDemoMode ? "DEMO LINK ACTIVE" : "VOICE LINK STANDBY"
        
        guard !AppRuntime.isDemoMode else { return }
        
        WebSocketService.shared.connect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            WebSocketService.shared.joinGameSession(sessionId: session.sessionId, userId: session.playerA_Id)
            AgoraService.shared.joinChannel(channelName: session.sessionId)
        }
        
        WebSocketService.shared.$activeClueIndex
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] newClueIndex in
                self?.revealedCluesCount = newClueIndex
                self?.missionStatusLine = "INTEL TRANSMISSION RECEIVED"
            }
            .store(in: &cancellables)
            
        WebSocketService.shared.$lastAttemptedAnswer
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.isMissionComplete = true
                self?.missionStatusLine = "TARGET SUBMISSION DETECTED"
                WebSocketService.shared.disconnect()
            }
            .store(in: &cancellables)
    }
    
    func revealNextClue() {
        if revealedCluesCount < session.clues.count {
            revealedCluesCount += 1
            missionStatusLine = "CLUE \(revealedCluesCount) TRANSMITTED"
            if !AppRuntime.isDemoMode {
                WebSocketService.shared.revealClue(sessionId: session.sessionId, clueIndex: revealedCluesCount)
            }
        }
    }
    
    func submitAnswer() {
        if !AppRuntime.isDemoMode {
            WebSocketService.shared.submitAnswer(sessionId: session.sessionId, answer: answerInput)
        }
        isMissionComplete = true
        session.isComplete = true
        session.outcome = answerInput.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare(session.expectedAnswer) == .orderedSame ? .success : .failed
        WebSocketService.shared.disconnect()
        AgoraService.shared.leaveChannel()
    }
    
    func terminateMission() {
        isMissionComplete = true
        session.isComplete = true
        session.outcome = .abandoned
        WebSocketService.shared.disconnect()
        AgoraService.shared.leaveChannel()
    }
    
    func requestHintFromGameMaster() {
        hintMessage = "REQUESTING GEMINI INTEL..."
        let currentTopic = session.trackTopic
        let activeClues = Array(session.clues.prefix(revealedCluesCount))
        
        Task {
            let hint: String
            if AppRuntime.isDemoMode {
                hint = DemoDataFactory.hint(for: session)
            } else {
                do {
                    hint = try await withTimeout {
                        try await GeminiService.shared.generateHint(topic: currentTopic, clues: activeClues)
                    }
                } catch {
                    hint = DemoDataFactory.hint(for: session)
                }
            }
            self.hintMessage = hint
            self.session.aiHintLog.append(hint)
        }
    }
}
