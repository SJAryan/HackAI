import Foundation

struct ParsedResumeData: Codable {
    var currentSkills: String
    var futureInterests: String
}

class ResumeParserService {
    static let shared = ResumeParserService()
    
    // We can reuse the Gemini API Key from GeminiService, but for independence we define it here,
    // or ideally fetch it from a secure environment/plist.
    private let apiKey = "AIzaSyDQ_LUqzbCaUp2zRiCKzdSfYJ7iBbNz8iY"
    private let baseUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash:generateContent"
    
    func parseResume(pdfText: String) async throws -> ParsedResumeData {
        guard let url = URL(string: "\(baseUrl)?key=\(apiKey)") else {
            throw URLError(.badURL)
        }
        
        let systemPrompt = """
        You are an elite operative AI parser. Your objective is to extract targeted intelligence from the provided dossier (resume text).
        Identify the subject's 'currentSkills' (technologies, tools, methodologies they already know) and their 'futureInterests' (what they want to learn or are aspiring towards).
        Return ONLY a valid JSON object matching exactly this schema:
        {
          "currentSkills": "A concise, comma-separated list of their core competencies.",
          "futureInterests": "A concise, comma-separated list of extrapolated future domains they are targeting."
        }
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
            print("Gemini API Error Response: \\(String(data: data, encoding: .utf8) ?? "Unknown")")
            throw URLError(.badServerResponse)
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let responseText = geminiResponse.candidates.first?.content.parts.first?.text else {
            throw URLError(.cannotParseResponse)
        }
        
        guard let jsonData = responseText.data(using: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        let parsedData = try JSONDecoder().decode(ParsedResumeData.self, from: jsonData)
        return parsedData
    }
}
