import Foundation

// MARK: - Gemini Request Models
struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let systemInstruction: GeminiSystemInstruction?
    let generationConfig: GeminiGenerationConfig?
}

struct GeminiContent: Codable {
    let role: String
    let parts: [GeminiPart]
}

struct GeminiSystemInstruction: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

struct GeminiGenerationConfig: Codable {
    let temperature: Double?
    let responseMimeType: String?
}

// MARK: - Gemini Response Models
struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
    let finishReason: String?
}
