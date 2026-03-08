import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct MatchmakerView: View {
    @StateObject private var viewModel = MatchmakerViewModel()
    @State private var showFilePicker = false
    @State private var extractedBio: String = ""
    @State private var pdfStatusMessage: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Synapse Matchmaker")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(viewModel.isMatching ? "Finding complementary peer via Atlas Vector Search..." : "Upload your resume to enter the lobby.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                if let session = viewModel.matchedSession {
                    VStack(spacing: 20) {
                        VStack(spacing: 10) {
                            Text("Match Found!")
                                .font(.headline)
                                .foregroundColor(.green)
                            Text("Topic: \(session.topic)")
                                .font(.subheadline)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        
                        NavigationLink(destination: ActiveMissionView(viewModel: ActiveMissionViewModel(session: session))) {
                            Text("Enter Lobby")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // --- PDF RESUME UPLOAD SECTION ---
                VStack(spacing: 10) {
                    Button(action: {
                        showFilePicker = true
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("Upload Resume (PDF)")
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.pdf], allowsMultipleSelection: false) { result in
                        do {
                            let selectedFiles = try result.get()
                            if let firstFile = selectedFiles.first {
                                extractText(from: firstFile)
                            }
                        } catch {
                            self.pdfStatusMessage = "❌ Error selecting file."
                        }
                    }
                    
                    if !pdfStatusMessage.isEmpty {
                        Text(pdfStatusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                Button(action: {
                    // Fallback to a stub if they click match without uploading a real PDF
                    let finalBio = extractedBio.isEmpty ? "I am a frontend Swift developer looking to learn more about backend logic." : extractedBio
                    viewModel.generateEmbeddingAndMatch(bio: finalBio)
                }) {
                    Text(viewModel.isMatching ? "Scanning..." : "Sync & Match")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((extractedBio.isEmpty && !viewModel.isMatching) ? Color.gray.opacity(0.5) : (viewModel.isMatching ? Color.gray : Color.blue))
                        .cornerRadius(12)
                }
                .disabled(viewModel.isMatching)
                .padding()
            }
            .padding()
        }
    }
    
    // MARK: - PDF Parsing Logic
    
    private func extractText(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            self.pdfStatusMessage = "❌ Access denied to file."
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        if let pdfDoc = PDFDocument(url: url) {
            var fullText = ""
            let pageCount = pdfDoc.pageCount
            
            for i in 0..<pageCount {
                if let page = pdfDoc.page(at: i), let pageText = page.string {
                    fullText += pageText + "\n"
                }
            }
            
            self.extractedBio = fullText
            
            // Just a quick visual validation for the user
            let wordCount = fullText.split { $0.isWhitespace || $0.isNewline }.count
            self.pdfStatusMessage = "✅ Resume Parsed (\(wordCount) words matched)"
            print("[PDFKit] Extracted \(wordCount) words from uploaded Resume.")
        } else {
            self.pdfStatusMessage = "❌ Failed to read PDF contents."
        }
    }
}

#Preview {
    MatchmakerView()
}
