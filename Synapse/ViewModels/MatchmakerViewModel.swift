import Foundation

class MatchmakerViewModel: ObservableObject {
    @Published var currentProfile: MatchProfile?
    @Published var isMatching: Bool = false
    @Published var matchedSession: GameSession?
    
    // MARK: - Matchmaking API
    
    func generateEmbeddingAndMatch(bio: String) {
        self.isMatching = true
        
        Task {
            do {
                print("[API] Submitting user bio for Vector Embedding & Atlas Matchmaking...")
                // Replace "localhost" with your Mac's IP if testing on a physical iPhone!
                guard let url = URL(string: "http://localhost:3000/match") else { return }
                
                // Using the uploaded PDF contents
                let requestBody: [String: Any] = [
                    "userId": "kevin_123",
                    "bio": bio,
                    "primaryRole": "technical"
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
                    
                    print("SUCCESS: Matched with complementary peer! Bio: \(peerBio) | Mastery: \(peerMastery) Stars")
                    print("[API] Submitting pair to Gemini Game Master to generate custom instruction module...")
                    
                    let prompt = "Create a cooperative puzzle. The topic is Backend Logic. Player A is a Frontend Swift Dev. Player B's bio: \(peerBio)."
                    
                    var sessionToStart: GameSession
                    do {
                        sessionToStart = try await GeminiService.shared.generateSkillModule(prompt: prompt)
                    } catch {
                        print("[ERROR] Gemini Game Master failed (\(error.localizedDescription)). Using fallback.")
                        sessionToStart = GameSession(id: UUID().uuidString, topic: "Backend Basics", playerAId: "kevin_123", playerBId: peerId, startTime: Date(), isActive: true, currentLevel: 1, clues: ["They are using Node.js", "Express handles the routes"], expectedAnswer: "API", peerMastery: peerMastery)
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
                        print("WAITING: Saved vector embedding to Atlas. Waiting for a complementary peer match...")
                    }
                }
            } catch {
                await MainActor.run {
                    self.isMatching = false
                    print("[ERROR] Matchmaking Failed: \(error.localizedDescription)")
                }
            }
        }
    }
}
