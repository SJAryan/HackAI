import Foundation

struct ParsedDossier: Codable {
    let currentSkills: [String]
    let futureInterests: [String]
    let suggestedRole: String
}

class ResumeParserService {
    static let shared = ResumeParserService()
    
    // We can reuse the Gemini API Key from GeminiService, but for independence we define it here,
    // or ideally fetch it from a secure environment/plist.
    private let apiKey = "AIzaSyDQ_LUqzbCaUp2zRiCKzdSfYJ7iBbNz8iY"
    private let baseUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash:generateContent"
    
    func parseResume(pdfText: String) async throws -> ParsedDossier {
        guard let url = URL(string: "\(baseUrl)?key=\(apiKey)") else {
            throw URLError(.badURL)
        }
        
        let systemPrompt = """
        You are an expert operative handler. Extract the candidate's data from the following resume text. Return a JSON object with exactly three keys: 'currentSkills' (array of strings, max 5), 'futureInterests' (array of strings, max 3), and 'suggestedRole' (a single string categorizing their primary domain, such as 'Management & Strategy', 'Backend Engineering', etc.).
        """
        
        // Truncate text if it's absurdly long, though Gemini 1.5/3.1 has a huge context window
        let truncatedText = String(pdfText.prefix(20000))
        
        let requestBody = GeminiRequest(
            contents: [GeminiContent(role: "user", parts: [GeminiPart(text: "Extract intelligence from this dossier:\\n\\(truncatedText)")])],
            systemInstruction: GeminiSystemInstruction(parts: [GeminiPart(text: systemPrompt)]),
            generationConfig: GeminiGenerationConfig(temperature: 0.2, responseMimeType: "application/json")
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown"
            print("Gemini API Error Response: \\(errorText)")
            throw URLError(.badServerResponse)
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let responseText = geminiResponse.candidates.first?.content.parts.first?.text else {
            throw URLError(.cannotParseResponse)
        }
        
        guard let jsonData = responseText.data(using: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        let parsedData = try JSONDecoder().decode(ParsedDossier.self, from: jsonData)
        return parsedData
    }
}
