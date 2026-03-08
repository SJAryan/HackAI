import Foundation

class ForgeViewModel: ObservableObject {
    @Published var promptInput: String = ""
    @Published var isGenerating: Bool = false
    @Published var successMessage: String?
    
    // MARK: - The Forge API
    
    func generateSkillModule() {
        guard !promptInput.isEmpty else { return }
        
        self.isGenerating = true
        self.successMessage = nil
        
        // Spawn an async Task to call our Gemini API Service
        Task {
            do {
                print("[API] Submitting prompt to Gemini: '\(promptInput)'")
                let newSession = try await GeminiService.shared.generateSkillModule(prompt: promptInput)
                
                // Save `newSession` to MongoDB Atlas!
                print("[API] Successfully generated module for topic: \(newSession.topic). Saving to Atlas...")
                
                guard let url = URL(string: "http://localhost:3000/forge") else { return }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(newSession)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                    await MainActor.run {
                        self.isGenerating = false
                        self.promptInput = ""
                        self.successMessage = "Successfully forged and published new Skill Module! Topic: \(newSession.topic)"
                    }
                } else {
                    throw URLError(.badServerResponse)
                }
                
            } catch {
                await MainActor.run {
                    self.isGenerating = false
                    print("[ERROR] Gemini API Failed: \(error.localizedDescription)")
                    self.successMessage = "Failed to forge module. Check API Key and Xcode console."
                }
            }
        }
    }
}
