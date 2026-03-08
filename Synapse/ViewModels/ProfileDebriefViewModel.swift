import Foundation

@MainActor
final class ProfileDebriefViewModel: ObservableObject {
    @Published var session: GameSession?
    @Published var report: DebriefReport?
    @Published var isLoadingDebrief: Bool = false
    @Published var visualMapPrompt: String = ""
    @Published var errorMessage: String = ""
    
    func generateDebrief(for session: GameSession, dossier: UserDossier? = nil, didWin: Bool = true) {
        self.session = session
        isLoadingDebrief = true
        errorMessage = ""
        
        Task {
            let debriefReport = await DallasAIService.shared.generateLearningMap(
                session: session,
                dossier: dossier,
                didWin: didWin
            )
            self.report = debriefReport
            self.visualMapPrompt = debriefReport.dallasVisualPrompt ?? DallasAIService.shared.buildVisualMapPrompt(report: debriefReport, topic: session.trackTopic)
            self.isLoadingDebrief = false
        }
    }
}
