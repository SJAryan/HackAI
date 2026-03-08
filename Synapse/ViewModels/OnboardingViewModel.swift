import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var step: Int = 1
    
    @Published var isParsingPDF: Bool = false
    @Published var pdfStatusMessage: String = ""
    @Published var rawPdfText: String = ""
    @Published var errorMessage: String = ""
    
    @Published var currentSkills: String = ""
    @Published var futureInterests: String = ""
    @Published var suggestedRole: String = ""
    @Published var selectedTrack: String = "Prompt Engineering"
    @Published var starMastery: Int = 3
    
    @Published var isMatching: Bool = false
    @Published var matchedSession: GameSession? = nil
    
    let tracks = ["Prompt Engineering", "AI Safety", "AI Agents", "Responsible AI", "Backend Systems"]
    
    private let localUserId = UUID().uuidString
    
    private func applyDossier(_ dossier: UserDossier, statusMessage: String) {
        rawPdfText = rawPdfText.isEmpty ? dossier.atlasSearchText : rawPdfText
        currentSkills = dossier.currentSkills.joined(separator: ", ")
        futureInterests = dossier.futureInterests.joined(separator: ", ")
        suggestedRole = dossier.suggestedRole
        starMastery = dossier.trackMastery
        isParsingPDF = false
        pdfStatusMessage = statusMessage
        step = 2
    }
    
    func parsePDFAndExtract(url: URL) {
        isParsingPDF = true
        pdfStatusMessage = "DOSSIER INGESTION IN PROGRESS..."
        errorMessage = ""
        
        Task {
            do {
                let fullText = try ResumeParserService.shared.extractText(from: url)
                let wordCount = fullText.split(whereSeparator: \.isWhitespace).count
                let parsedDossier: UserDossier
                
                if AppRuntime.isDemoMode {
                    parsedDossier = DemoDataFactory.dossier(id: localUserId)
                } else {
                    parsedDossier = try await withTimeout {
                        try await ResumeParserService.shared.parseResume(pdfText: fullText)
                    }
                }
                
                DispatchQueue.main.async {
                    self.rawPdfText = fullText
                    self.applyDossier(parsedDossier, statusMessage: "DOSSIER PARSED: \(wordCount) WORDS EXTRACTED.")
                }
            } catch {
                DispatchQueue.main.async {
                    self.applyDossier(DemoDataFactory.dossier(id: self.localUserId), statusMessage: "DOSSIER PARSED: FALLBACK INTELLIGENCE LOADED.")
                }
            }
        }
    }
    
    private func parseCSVLine(_ value: String) -> [String] {
        value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    func buildDossier() -> UserDossier {
        var interests = parseCSVLine(futureInterests)
        if !interests.contains(selectedTrack) {
            interests.insert(selectedTrack, at: 0)
        }
        
        return UserDossier(
            id: localUserId,
            currentSkills: parseCSVLine(currentSkills),
            futureInterests: interests,
            suggestedRole: suggestedRole.isEmpty ? "Adaptive Operative" : suggestedRole,
            trackMastery: starMastery
        )
    }
    
    func submitDossierAndMatch() {
        let dossier = buildDossier()
        isMatching = true
        errorMessage = ""
        
        Task {
            let assignedRole: OperativeRole = Bool.random() ? .controls : .intel
            do {
                let match: MatchmakerResponse
                if AppRuntime.isDemoMode {
                    match = DemoDataFactory.matchResponse(for: dossier)
                } else {
                    match = try await withTimeout {
                        try await MatchmakerService.shared.findMatch(for: dossier)
                    }
                }
                
                guard match.status == "success" else {
                    throw URLError(.resourceUnavailable)
                }
                
                let session: GameSession
                if AppRuntime.isDemoMode {
                    var mockSession = DemoDataFactory.mission(for: dossier, assignedRole: assignedRole)
                    mockSession.peerSuggestedRole = match.peerRole
                    mockSession.peerSummary = match.peerSummary
                    mockSession.matchScore = match.matchScore
                    session = mockSession
                } else {
                    let missionPrompt = """
                    Build a 15-minute asymmetric co-op learning mission.
                    Topic: \(match.trackTopic ?? selectedTrack)
                    Local dossier: \(dossier.atlasSearchText)
                    Matched peer role: \(match.peerRole ?? "Unknown")
                    Matched peer summary: \(match.peerSummary ?? "No peer summary provided.")
                    The local player's assigned role should be \(assignedRole.rawValue).
                    """
                    
                    session = try await withTimeout {
                        try await GeminiService.shared.generateSkillModule(prompt: missionPrompt)
                    }
                }
                
                var hydratedSession = session
                hydratedSession.sessionId = hydratedSession.sessionId.isEmpty ? UUID().uuidString : hydratedSession.sessionId
                hydratedSession.playerA_Id = localUserId
                hydratedSession.playerB_Id = match.peerId ?? "pending-peer"
                hydratedSession.trackTopic = match.trackTopic ?? selectedTrack
                hydratedSession.localAssignedRole = assignedRole
                hydratedSession.startedAt = Date()
                hydratedSession.isComplete = false
                hydratedSession.peerSuggestedRole = match.peerRole
                hydratedSession.peerSummary = match.peerSummary
                hydratedSession.matchScore = match.matchScore
                
                DispatchQueue.main.async {
                    self.isMatching = false
                    self.matchedSession = hydratedSession
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = ""
                }
                simulateMatch()
            }
        }
    }
    
    func simulateMatch() {
        isMatching = true
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            let dossier = buildDossier()
            var mockSession = DemoDataFactory.mission(for: dossier, assignedRole: .controls)
            mockSession.trackTopic = selectedTrack
            
            DispatchQueue.main.async {
                self.isMatching = false
                self.matchedSession = mockSession
            }
        }
    }
}
