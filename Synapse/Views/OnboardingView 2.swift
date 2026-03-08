import SwiftUI
import UniformTypeIdentifiers

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var showFilePicker = false
    
    // A dark, high-stakes color palette
    private let bgColor = Color(red: 0.05, green: 0.05, blue: 0.08)
    private let accentColor = Color(red: 0.0, green: 0.8, blue: 0.4) // Hacker green
    private let cardColor = Color(red: 0.1, green: 0.1, blue: 0.15)
    
    var body: some View {
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea()
                
                if let session = viewModel.matchedSession {
                    matchFoundView(session: session)
                } else {
                    VStack(spacing: 30) {
                        headerView
                        
                        if viewModel.step == 1 {
                            step1View
                        } else {
                            step2View
                        }
                        
                        Spacer()
                        
                        if viewModel.step == 2 {
                            Button(action: {
                                viewModel.submitDossierAndMatch()
                            }) {
                                HStack {
                                    if viewModel.isMatching {
                                        ProgressView().tint(.black)
                                        Text("Initializing Vector Sync...")
                                    } else {
                                        Text("EXECUTE MATCHMAKING PROTOCOL")
                                            .fontWeight(.bold)
                                    }
                                }
                                .font(.system(.headline, design: .monospaced))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(viewModel.isMatching ? Color.gray : accentColor)
                                .cornerRadius(8)
                            }
                            .disabled(viewModel.isMatching || viewModel.currentSkills.isEmpty)
                        }
                    }
                    .padding(24)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("OPERATIVE DOSSIER")
                .font(.system(.title, design: .monospaced))
                .fontWeight(.black)
                .foregroundColor(.white)
                .kerning(2)
            
            Text(viewModel.step == 1 ? "PHASE 1: BACKGROUND INTEL" : "PHASE 2: CAPABILITY MATRIX")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(accentColor)
        }
        .padding(.top, 20)
    }
    
    private var step1View: some View {
        VStack(spacing: 24) {
            Image(systemName: "fingerprint")
                .font(.system(size: 60))
                .foregroundColor(accentColor.opacity(0.8))
                .padding(.vertical)
            
            Text("To calculate the optimal operational pairing, we require your background data.")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button(action: { showFilePicker = true }) {
                HStack {
                    Image(systemName: "doc.viewfinder")
                    Text("UPLOAD PDF RESUME")
                }
                .font(.system(.headline, design: .monospaced))
                .foregroundColor(accentColor)
                .frame(maxWidth: .infinity)
                .padding()
                .background(cardColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(accentColor.opacity(0.5), lineWidth: 1)
                )
            }
            .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.pdf]) { result in
                if let url = try? result.get().first {
                    viewModel.parsePDFAndExtract(url: url)
                }
            }
            
            if viewModel.isParsingPDF {
                ProgressView("Extracting Intelligence via Gemini...")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.white)
                    .padding()
            }
            
            if !viewModel.pdfStatusMessage.isEmpty {
                Text(viewModel.pdfStatusMessage)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(viewModel.pdfStatusMessage.contains("❌") ? .red : accentColor)
            }
            
            // Allow manual bypass
            Button("BYPASS TO MANUAL ENTRY") {
                withAnimation { viewModel.step = 2 }
            }
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(.gray)
            .padding(.top)
        }
    }
    
    private var step2View: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // Track Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("TARGET OPERATIONAL TRACK")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)
                    
                    Picker("Track", selection: $viewModel.selectedTrack) {
                        ForEach(viewModel.tracks, id: \\.self) { track in
                            Text(track).tag(track)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(cardColor)
                    .cornerRadius(8)
                }
                
                // Mastery Slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("BASELINE MASTERY OVERRIDE")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\\(viewModel.starMastery) STAR")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(accentColor)
                    }
                    
                    Slider(value: Binding(
                        get: { Double(viewModel.starMastery) },
                        set: { viewModel.starMastery = Int($0) }
                    ), in: 1...5, step: 1)
                    .tint(accentColor)
                }
                
                // Skills (Auto-filled by Gemini)
                VStack(alignment: .leading, spacing: 8) {
                    Text("CONFIRMED CURRENT SKILLS")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)
                    
                    TextEditor(text: $viewModel.currentSkills)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(height: 80)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(cardColor)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                // Interests (Auto-filled by Gemini)
                VStack(alignment: .leading, spacing: 8) {
                    Text("IDENTIFIED FUTURE TARGETS")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)
                    
                    TextEditor(text: $viewModel.futureInterests)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(height: 80)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(cardColor)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
    }
    
    private func matchFoundView(session: GameSession) -> some View {
        VStack(spacing: 30) {
            Image(systemName: "link")
                .font(.system(size: 60))
                .foregroundColor(accentColor)
            
            Text("TARGET SECURED")
                .font(.system(.title, design: .monospaced))
                .fontWeight(.black)
                .foregroundColor(.white)
                .kerning(2)
            
            VStack(spacing: 12) {
                Text("ASSET: P\\(session.playerBId.prefix(4).uppercased())")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.gray)
                
                Text(session.topic.uppercased())
                    .font(.system(.headline, design: .monospaced))
                    .foregroundColor(accentColor)
            }
            .padding(24)
            .background(cardColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
            )
            
            NavigationLink(destination: ActiveMissionView(viewModel: ActiveMissionViewModel(session: session))) {
                Text("INITIATE LINK")
                    .font(.system(.headline, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(accentColor)
                    .cornerRadius(8)
            }
            .padding(.top, 20)
        }
        .padding(30)
    }
}

#Preview {
    OnboardingView()
}
