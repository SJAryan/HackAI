import Foundation

enum GeminiServiceError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case emptyResponse
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "GEMINI_API_KEY is not configured."
        case .invalidResponse:
            return "Gemini returned an invalid response."
        case .emptyResponse:
            return "Gemini returned an empty response."
        }
    }
}

class GeminiService {
    static let shared = GeminiService()
    static var configuredAPIKey: String? {
        ProcessInfo.processInfo.environment["GEMINI_API_KEY"]
    }
    
    private let apiKey: String?
    private let baseUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash:generateContent"
    
    private init() {
        self.apiKey = Self.configuredAPIKey
    }
    
    // MARK: - Shared Request Pipeline
    
    private func makeURL() throws -> URL {
        guard let apiKey, !apiKey.isEmpty else {
            throw GeminiServiceError.missingAPIKey
        }
        guard let url = URL(string: "\(baseUrl)?key=\(apiKey)") else {
            throw URLError(.badURL)
        }
        return url
    }
    
    private func sendTextRequest(
        userPrompt: String,
        systemPrompt: String,
        temperature: Double,
        responseMimeType: String
    ) async throws -> String {
        let requestBody = GeminiRequest(
            contents: [GeminiContent(role: "user", parts: [GeminiPart(text: userPrompt)])],
            systemInstruction: GeminiSystemInstruction(parts: [GeminiPart(text: systemPrompt)]),
            generationConfig: GeminiGenerationConfig(
                temperature: temperature,
                responseMimeType: responseMimeType
            )
        )
        
        var request = URLRequest(url: try makeURL())
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print("Gemini API Error Response: \(String(data: data, encoding: .utf8) ?? "Unknown")")
            throw URLError(.badServerResponse)
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let responseText = geminiResponse.candidates.first?.content.parts.first?.text,
              !responseText.isEmpty else {
            throw GeminiServiceError.emptyResponse
        }
        
        return responseText
    }
    
    private func sendJSONRequest<T: Decodable>(
        userPrompt: String,
        systemPrompt: String,
        temperature: Double = 0.3,
        type: T.Type
    ) async throws -> T {
        let responseText = try await sendTextRequest(
            userPrompt: userPrompt,
            systemPrompt: systemPrompt,
            temperature: temperature,
            responseMimeType: "application/json"
        )
        
        guard let jsonData = responseText.data(using: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: jsonData)
    }
    
    // MARK: - API Calls
    
    func generateSkillModule(prompt: String) async throws -> GameSession {
        let systemPrompt = """
        You are the mission designer for SYNAPSE, an asymmetric co-op learning game.
        Return ONLY valid JSON matching this schema exactly:
        {
          "sessionId": "uuid",
          "playerA_Id": "controls-operative",
          "playerB_Id": "intel-operative",
          "trackTopic": "Prompt Engineering",
          "isComplete": false,
          "missionBrief": "One short paragraph briefing the pair on the mission objective.",
          "clues": ["Clue 1", "Clue 2", "Clue 3", "Clue 4"],
          "expectedAnswer": "exact answer controls should submit",
          "localAssignedRole": "Controls",
          "startedAt": "2026-03-08T00:00:00Z",
          "durationSeconds": 900,
          "outcome": "pending",
          "aiHintLog": [],
          "peerMastery": 3,
          "peerSuggestedRole": "Backend Engineering",
          "peerSummary": "Optional one-line summary",
          "matchScore": 0.91
        }
        Keep clues short, high-signal, and cooperative. The expected answer should be concise.
        """
        
        var session = try await sendJSONRequest(
            userPrompt: prompt,
            systemPrompt: systemPrompt,
            temperature: 0.7,
            type: GameSession.self
        )
        if session.clues.isEmpty {
            session.clues = ["Clarify the core concept.", "Translate the clue into action.", "Submit the final phrase."]
        }
        return session
    }
    
    func generateHint(topic: String, clues: [String]) async throws -> String {
        let systemPrompt = """
        You are the SYNAPSE mission operator.
        The pair is stuck on the topic "\(topic)".
        Existing clues: \(clues.joined(separator: " | ")).
        Provide one cryptic but useful hint under 18 words. Do not reveal the exact answer.
        """
        
        return try await sendTextRequest(
            userPrompt: "Request one mission hint.",
            systemPrompt: systemPrompt,
            temperature: 0.9,
            responseMimeType: "text/plain"
        )
    }
    
    func generateDebrief(session: GameSession, dossier: UserDossier? = nil, didWin: Bool = true) async throws -> DebriefReport {
        let timeTaken = session.durationSeconds - session.timeRemaining
        let dossierSummary = dossier?.atlasSearchText ?? "No dossier supplied."
        let systemPrompt = """
        You are the SYNAPSE Mission Debrief analyst.
        Return ONLY valid JSON matching this schema exactly:
        {
          "id": "uuid",
          "sessionId": "\(session.sessionId)",
          "userId": "\(session.playerA_Id)",
          "communicationScore": 85,
          "completionTimeSeconds": \(timeTaken),
          "conceptsMastered": ["String 1", "String 2"],
          "areasForImprovement": ["String 1", "String 2"],
          "nextSteps": ["String 1", "String 2", "String 3"],
          "recommendedVideoLinks": ["https://youtube.com/watch?v=123"],
          "visualMapNodes": [
            {
              "id": "node_1",
              "title": "Topic Name",
              "description": "Short personalized advice tied to performance",
              "recommendedYoutubeUrl": "https://youtube.com/watch?v=123",
              "timestamp": "2m 10s"
            }
          ],
          "dallasVisualPrompt": "A dark thriller-style learning map with neon green path nodes and dossier labels."
        }
        Base the report on the mission topic, cooperative performance, and this dossier summary: \(dossierSummary)
        Mission topic: \(session.trackTopic)
        Mission outcome: \(didWin ? "success" : "failed")
        """
        
        return try await sendJSONRequest(
            userPrompt: "Generate a mission debrief.",
            systemPrompt: systemPrompt,
            temperature: 0.8,
            type: DebriefReport.self
        )
    }
}
