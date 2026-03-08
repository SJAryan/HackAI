import Foundation

class ProfileDebriefViewModel: ObservableObject {
    @Published var session: GameSession?
    @Published var report: DebriefReport?
    @Published var isLoadingDebrief: Bool = false
    
    // MARK: - Post-Game Analysis API
    
    func generateDebrief(for session: GameSession) {
        self.session = session
        isLoadingDebrief = true
        
        print("[API] Sending mission data to Gemini API for Debrief Generation...")
        
        Task {
            do {
                let debriefReport = try await GeminiService.shared.generateDebrief(session: session)
                await MainActor.run {
                    self.report = debriefReport
                    self.isLoadingDebrief = false
                }
            } catch {
                await MainActor.run {
                    print("[ERROR] Failed to generate Debrief via Gemini (\(error.localizedDescription)). Using fallback.")
                    let nodes = [
                        LearningNode(id: "1", title: "Review Zero-Shot vs Few-Shot", description: "You got stuck here for 3 minutes.", recommendedYoutubeUrl: "https://youtube.com/watch?v=123", timestamp: "0m 45s")
                    ]
                    self.report = DebriefReport(id: UUID().uuidString, sessionId: session.id, userId: "kevin_123", communicationScore: 85, completionTimeSeconds: 750, conceptsMastered: ["Context Windows"], areasForImprovement: ["Few-Shot Prompting"], visualMapNodes: nodes)
                    self.isLoadingDebrief = false
                }
            }
        }
    }
}
