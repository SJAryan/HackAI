import Foundation
import PDFKit

final class ResumeParserService {
    static let shared = ResumeParserService()
    
    private let apiKey: String?
    private let baseUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash:generateContent"
    
    private init() {
        self.apiKey = GeminiService.configuredAPIKey
    }
    
    func extractText(from url: URL) throws -> String {
        guard url.startAccessingSecurityScopedResource() else {
            throw CocoaError(.fileReadNoPermission)
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        guard let document = PDFDocument(url: url) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        var fullText = ""
        for pageIndex in 0..<document.pageCount {
            if let page = document.page(at: pageIndex), let text = page.string {
                fullText += text + "\n"
            }
        }
        
        return fullText
    }
    
    func parseResume(pdfText: String) async throws -> UserDossier {
        guard let apiKey, !apiKey.isEmpty else {
            throw GeminiServiceError.missingAPIKey
        }
        let truncatedText = String(pdfText.prefix(20_000))
        let systemPrompt = """
        You are an expert dossier analyst for SYNAPSE.
        Read the resume text and return ONLY valid JSON matching this schema:
        {
          "id": "uuid",
          "currentSkills": ["skill 1", "skill 2", "skill 3"],
          "futureInterests": ["interest 1", "interest 2", "interest 3"],
          "suggestedRole": "Backend Engineering",
          "trackMastery": 3
        }
        Rules:
        - Keep currentSkills to 3-6 concise items.
        - Infer futureInterests from the candidate's projects, goals, and trajectory.
        - suggestedRole must be a short category label.
        - trackMastery must be an integer from 1 to 5.
        """
        
        let requestBody = GeminiRequest(
            contents: [GeminiContent(role: "user", parts: [GeminiPart(text: "Analyze this resume text:\n\(truncatedText)")])],
            systemInstruction: GeminiSystemInstruction(parts: [GeminiPart(text: systemPrompt)]),
            generationConfig: GeminiGenerationConfig(temperature: 0.2, responseMimeType: "application/json")
        )
        
        guard let url = URL(string: "\(baseUrl)?key=\(apiKey)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print("Resume parser Gemini error: \(String(data: data, encoding: .utf8) ?? "Unknown")")
            throw URLError(.badServerResponse)
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let responseText = geminiResponse.candidates.first?.content.parts.first?.text,
              let jsonData = responseText.data(using: .utf8) else {
            throw URLError(.cannotParseResponse)
        }
        
        return try JSONDecoder().decode(UserDossier.self, from: jsonData)
    }
}
