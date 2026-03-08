import Foundation

final class DallasAIService {
    static let shared = DallasAIService()
    
    private init() {}
    
    func generateLearningMap(
        session: GameSession,
        dossier: UserDossier? = nil,
        didWin: Bool = true
    ) async -> DebriefReport {
        if AppRuntime.isDemoMode {
            return DemoDataFactory.debrief(for: session, didWin: didWin)
        }
        
        do {
            var report = try await withTimeout {
                try await GeminiService.shared.generateDebrief(session: session, dossier: dossier, didWin: didWin)
            }
            report.dallasVisualPrompt = buildVisualMapPrompt(report: report, topic: session.trackTopic)
            return report
        } catch {
            return DemoDataFactory.debrief(for: session, didWin: didWin)
        }
    }
    
    func buildVisualMapPrompt(report: DebriefReport, topic: String) -> String {
        let mastered = report.conceptsMastered.joined(separator: ", ")
        let next = report.nextSteps.joined(separator: ", ")
        return """
        Create a dark operative dossier visual map for \(topic). Use charcoal backgrounds, neon green pathways, monospaced labels, and node clusters for mastered concepts (\(mastered)) and next steps (\(next)).
        """
    }
}
