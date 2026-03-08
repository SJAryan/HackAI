import Foundation

struct MatchmakerResponse: Codable {
    let status: String
    let message: String
    let peerId: String?
    let peerRole: String?
    let peerSummary: String?
    let trackTopic: String?
    let matchScore: Double?
}

final class MatchmakerService {
    static let shared = MatchmakerService()
    
    // For simulator use localhost. For a physical device, replace with your Mac's LAN IP.
    private let baseURL = "http://localhost:3000"
    
    private init() {}
    
    func findMatch(for dossier: UserDossier) async throws -> MatchmakerResponse {
        guard let url = URL(string: "\(baseURL)/match") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(dossier)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(MatchmakerResponse.self, from: data)
    }
    
    func publishMission(_ session: GameSession) async throws {
        guard let url = URL(string: "\(baseURL)/forge") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(session)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
