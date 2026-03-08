import Foundation

class GeminiService {
    static let shared = GeminiService()
    
    // ⚠️ HACKATHON TODO: Paste your Gemini API Key here from Google AI Studio
    private let apiKey = "AIzaSyDQ_LUqzbCaUp2zRiCKzdSfYJ7iBbNz8iY"
    private let baseUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash:generateContent"
    
    // MARK: - API Calls
    
    func generateSkillModule(prompt: String) async throws -> GameSession {
        guard let url = URL(string: "\(baseUrl)?key=\(apiKey)") else {
            throw URLError(.badURL)
        }
        
        // Define the AI Game Master's persona and instructions
        let systemPrompt = """
        You are the 'Game Master' for an asymmetric learning game. 
        The user will provide a topic. 
        You must generate a 15-minute game scenario returning ONLY a valid JSON object matching this Swift structure:
        {
          "id": "uuid",
          "topic": "The user's topic",
          "playerAId": "",
          "playerBId": "",
          "startTime": \(Date().timeIntervalSince1970),
          "durationMinutes": 15,
          "isActive": false,
          "currentLevel": 1,
          "clues": ["Clue 1 for Player B", "Clue 2 for Player B", "Clue 3 for Player B"],
          "expectedAnswer": "The exact short phrase Player A must type to win"
        }
        """
        
        let requestBody = GeminiRequest(
            contents: [GeminiContent(role: "user", parts: [GeminiPart(text: prompt)])],
            systemInstruction: GeminiSystemInstruction(parts: [GeminiPart(text: systemPrompt)]),
            generationConfig: GeminiGenerationConfig(temperature: 0.7, responseMimeType: "application/json")
        )
        
        var request = URLRequest(url: url)
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
        
        guard let responseText = geminiResponse.candidates.first?.content.parts.first?.text else {
            throw URLError(.cannotParseResponse)
        }
        
        // Gemini returns the JSON as a text block, decode it back to our GameSession model
        guard let sessionData = responseText.data(using: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let gameSession = try decoder.decode(GameSession.self, from: sessionData)
        
        return gameSession
    }
    
    func generateHint(topic: String, clues: [String]) async throws -> String {
        guard let url = URL(string: "\(baseUrl)?key=\(apiKey)") else {
            throw URLError(.badURL)
        }
        
        let systemPrompt = """
        You are the 'Game Master' for an asymmetric learning game.
        The players are stuck on the topic: \(topic).
        Here are the clues they have received so far: \(clues.joined(separator: ", ")).
        Provide a very short, cryptic hint (under 15 words) to help them without giving away the exact answer.
        """
        
        let requestBody = GeminiRequest(
            contents: [GeminiContent(role: "user", parts: [GeminiPart(text: "Give us a hint!")])],
            systemInstruction: GeminiSystemInstruction(parts: [GeminiPart(text: systemPrompt)]),
            generationConfig: GeminiGenerationConfig(temperature: 0.9, responseMimeType: "text/plain")
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let responseText = geminiResponse.candidates.first?.content.parts.first?.text else {
            throw URLError(.cannotParseResponse)
        }
        
        return responseText
    }
    
    func generateDebrief(session: GameSession) async throws -> DebriefReport {
        guard let url = URL(string: "\(baseUrl)?key=\(apiKey)") else {
            throw URLError(.badURL)
        }
        
        let timeTaken = (session.durationMinutes * 60) - Int(session.timeRemaining)
        let systemPrompt = """
        You are the 'Debrief Tutor' for an asymmetric tech learning game.
        The players just finished a '\(session.topic)' mission in \(timeTaken) seconds.
        Analyze their performance and return ONLY a valid JSON object matching this Swift structure EXACTLY:
        {
          "id": "uuid",
          "sessionId": "\(session.id)",
          "userId": "kevin_123",
          "communicationScore": 85,
          "completionTimeSeconds": \(timeTaken),
          "conceptsMastered": ["String 1", "String 2"],
          "areasForImprovement": ["String 1"],
          "visualMapNodes": [
            {
              "id": "node_1",
              "title": "Topic Name",
              "description": "Short personalized advice",
              "recommendedYoutubeUrl": "https://youtube.com/watch?v=oHg5SJYRHA0",
              "timestamp": "1m 20s"
            }
          ]
        }
        Make up a creative, plausible learning map and realistic YouTube URL (e.g. a popular coding channel) for the next steps!
        """
        
        let requestBody = GeminiRequest(
            contents: [GeminiContent(role: "user", parts: [GeminiPart(text: "Generate our personalized post-game debrief!")])],
            systemInstruction: GeminiSystemInstruction(parts: [GeminiPart(text: systemPrompt)]),
            generationConfig: GeminiGenerationConfig(temperature: 0.8, responseMimeType: "application/json")
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let responseText = geminiResponse.candidates.first?.content.parts.first?.text else {
            throw URLError(.cannotParseResponse)
        }
        
        guard let debriefData = responseText.data(using: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        let decoder = JSONDecoder()
        let report = try decoder.decode(DebriefReport.self, from: debriefData)
        
        return report
    }
}
