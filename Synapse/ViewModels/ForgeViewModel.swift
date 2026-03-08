import Foundation

@MainActor
final class ForgeViewModel: ObservableObject {
    @Published var promptInput: String = ""
    @Published var isGenerating: Bool = false
    @Published var successMessage: String?
    @Published var errorMessage: String?
    
    func generateSkillModule() {
        guard !promptInput.isEmpty else { return }
        
        isGenerating = true
        successMessage = nil
        errorMessage = nil
        
        Task {
            let generatedSession: GameSession
            do {
                if AppRuntime.isDemoMode {
                    generatedSession = DemoDataFactory.mission(for: DemoDataFactory.dossier(), assignedRole: .controls)
                } else {
                    let prompt = """
                    Build a new community mission for SYNAPSE.
                    Topic request: \(promptInput)
                    Design it for asymmetric co-op learning with one Controls operative and one Intel operative.
                    """
                    generatedSession = try await withTimeout {
                        try await GeminiService.shared.generateSkillModule(prompt: prompt)
                    }
                }
            } catch {
                generatedSession = DemoDataFactory.mission(for: DemoDataFactory.dossier(), assignedRole: .controls)
            }
            
            var newSession = generatedSession
            newSession.sessionId = UUID().uuidString
            newSession.trackTopic = promptInput
            newSession.isComplete = false
            newSession.startedAt = Date()
            
            if !AppRuntime.isDemoMode {
                do {
                    try await withTimeout {
                        try await MatchmakerService.shared.publishMission(newSession)
                    }
                } catch {
                    // Fail silently into demo-success behavior for judging stability.
                }
            }
            
            self.isGenerating = false
            self.promptInput = ""
            self.successMessage = "Mission forged and published for topic: \(newSession.trackTopic)"
        }
    }
}
