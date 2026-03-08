import Foundation
import Combine

@MainActor
class ActiveMissionViewModel: ObservableObject {
    @Published var session: GameSession
    @Published var isPlayerA: Bool = true // A = Controls, B = Intel
    @Published var revealedCluesCount: Int = 1
    @Published var answerInput: String = ""
    @Published var isMissionComplete: Bool = false
    @Published var hintMessage: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init(session: GameSession) {
        self.session = session
        
        // Connect to Socket server when mission starts
        WebSocketService.shared.connect()
        // Wait briefly for connection, then join room
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            WebSocketService.shared.joinGameSession(sessionId: session.id, userId: "kevin_123")
            // Join the Agora Live Voice Channel!
            AgoraService.shared.joinChannel(channelName: session.id)
        }
        
        // Listen for Real-Time State changes from WebSockets
        WebSocketService.shared.$activeClueIndex
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] newClueIndex in
                self?.revealedCluesCount = newClueIndex
                self?.hintMessage = "Partner revealed a new clue!"
            }
            .store(in: &cancellables)
            
        WebSocketService.shared.$lastAttemptedAnswer
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] answer in
                // For hackathon: if someone submits an answer, assume success and jump to Debrief
                self?.isMissionComplete = true
                WebSocketService.shared.disconnect()
            }
            .store(in: &cancellables)
    }
    
    func revealNextClue() {
        if revealedCluesCount < session.clues.count {
            revealedCluesCount += 1
            WebSocketService.shared.revealClue(sessionId: session.id, clueIndex: revealedCluesCount)
        }
    }
    
    func submitAnswer() {
        WebSocketService.shared.submitAnswer(sessionId: session.id, answer: answerInput)
        isMissionComplete = true
        WebSocketService.shared.disconnect()
        // Disconnect from the Audio stream
        AgoraService.shared.leaveChannel()
    }
    
    func advanceLevel() {
        // TODO: Real-time sync via Agora or WebSockets
        print("[API] Syncing new level state to peer...")
        session.currentLevel += 1
    }
    
    func requestHintFromGameMaster() {
        self.hintMessage = "Asking the Game Master..."
        let currentTopic = session.topic
        let activeClues = Array(session.clues.prefix(revealedCluesCount))
        
        Task {
            do {
                print("[API] Calling Gemini API for a contextual hint based on current state...")
                let hint = try await GeminiService.shared.generateHint(topic: currentTopic, clues: activeClues)
                await MainActor.run {
                    self.hintMessage = "[Gemini Intel]: \(hint)"
                }
            } catch {
                await MainActor.run {
                    self.hintMessage = "The Game Master is currently unavailable."
                    print("Gemini Hint Error: \(error.localizedDescription)")
                }
            }
        }
    }
}
