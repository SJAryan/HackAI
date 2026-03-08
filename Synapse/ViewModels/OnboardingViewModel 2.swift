import SwiftUI
import PDFKit

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var step: Int = 1
    
    // Step 1: Resume Upload
    @Published var isParsingPDF: Bool = false
    @Published var pdfStatusMessage: String = ""
    @Published var rawPdfText: String = ""
    
    // Step 2 & 3: Questionnaire Answers
    @Published var currentSkills: String = ""
    @Published var futureInterests: String = ""
    @Published var selectedTrack: String = "Prompt Engineering"
    @Published var starMastery: Int = 3
    
    // Matchmaker Integration
    @Published var isMatching: Bool = false
    @Published var matchedSession: GameSession? = nil
    
    let tracks = ["Prompt Engineering", "AI Safety", "Privacy", "AI Dev"]
    
    // MARK: - PDF Parsing & Gemini Prefill
    
    func parsePDFAndExtract(url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            self.pdfStatusMessage = "❌ Access denied to file."
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        if let pdfDoc = PDFDocument(url: url) {
            var fullText = ""
            for i in 0..<pdfDoc.pageCount {
                if let page = pdfDoc.page(at: i), let pageText = page.string {
                    fullText += pageText + "\\n"
                }
            }
            
            self.rawPdfText = fullText
            let wordCount = fullText.split { $0.isWhitespace || $0.isNewline }.count
            self.pdfStatusMessage = "✅ Dossier Acquired (\\(wordCount) words). Running AI Extraction..."
            self.isParsingPDF = true
            
            Task {
                do {
                    let parsedData = try await ResumeParserService.shared.parseResume(pdfText: fullText)
                    await MainActor.run {
                        self.currentSkills = parsedData.currentSkills
                        self.futureInterests = parsedData.futureInterests
                        self.isParsingPDF = false
                        self.step = 2 // Auto-advance to Questionnaire
                    }
                } catch {
                    await MainActor.run {
                        self.pdfStatusMessage = "⚠️ Extraction failed. Please manually enter your intel."
                        self.isParsingPDF = false
                        self.step = 2 // Advance anyway
                    }
                }
            }
            
        } else {
            self.pdfStatusMessage = "❌ Failed to read PDF contents."
        }
    }
    
    // MARK: - Final Submit to Matchmaker
    
    func submitDossierAndMatch() {
        self.isMatching = true
        
        Task {
            do {
                print("[API] Submitting full Operative Dossier for Vector Matchmaking...")
                guard let url = URL(string: "http://localhost:3000/match") else { return }
                
                // Construct the "Rich Profile String"
                let richBio = "Track: \\(selectedTrack) | Mastery: \\(starMastery) Stars | Skills: \\(currentSkills) | Target Interests: \\(futureInterests) | Extracted Resume Background: \\(rawPdfText)"
                
                let requestBody: [String: Any] = [
                    "userId": "kevin_123", // Or dynamic user ID
                    "bio": richBio,
                    "primaryRole": selectedTrack,
                    "masteryLevel": starMastery
                ]
                let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = jsonData
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse, 
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let status = jsonResult?["status"] as? String ?? ""
                
                if status == "success" {
                    let peerId = jsonResult?["peerId"] as? String ?? "Unknown Peer"
                    let peerBio = jsonResult?["peerBio"] as? String ?? "No bio"
                    let peerMastery = jsonResult?["peerMastery"] as? Int ?? 3
                    
                    print("SUCCESS: Matched! Peer Bio: \\(peerBio)")
                    let prompt = "Create a cooperative puzzle. The topic is \\(selectedTrack). Player A's skills: \\(currentSkills), interests: \\(futureInterests). Player B's bio: \\(peerBio)."
                    
                    var sessionToStart: GameSession
                    do {
                        sessionToStart = try await GeminiService.shared.generateSkillModule(prompt: prompt)
                    } catch {
                        sessionToStart = GameSession(id: UUID().uuidString, topic: selectedTrack, playerAId: "kevin_123", playerBId: peerId, startTime: Date(), isActive: true, currentLevel: 1, clues: ["Fallback Clue 1", "Fallback Clue 2"], expectedAnswer: "API", peerMastery: peerMastery)
                    }
                    
                    sessionToStart.id = UUID().uuidString
                    sessionToStart.playerAId = "kevin_123"
                    sessionToStart.playerBId = peerId
                    sessionToStart.peerMastery = peerMastery
                    
                    await MainActor.run {
                        self.isMatching = false
                        self.matchedSession = sessionToStart
                    }
                } else {
                    await MainActor.run {
                        self.isMatching = false
                        print("WAITING: Dossier securely lodged in Atlas vector state.")
                    }
                }
            } catch {
                await MainActor.run {
                    self.isMatching = false
                    print("[ERROR] Database/Vector Search Failed: \\(error.localizedDescription)")
                }
            }
        }
    }
}
