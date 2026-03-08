import SwiftUI

struct DebriefView: View {
    @StateObject private var viewModel = ProfileDebriefViewModel()
    let session: GameSession
    
    var body: some View {
        ZStack {
            SynapseTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("MISSION DEBRIEF")
                        .font(SynapseTheme.font(.title2, weight: .black))
                        .fontWeight(.black)
                        .foregroundColor(.white)
                    
                    dossierCard(title: "SESSION SUMMARY", body: "Track: \(session.trackTopic)\nOutcome: \(session.outcome.rawValue.uppercased())\nElapsed: \(session.durationSeconds - session.timeRemaining)s")
                    
                    if viewModel.isLoadingDebrief {
                        ProgressView("ASSEMBLING DEBRIEF...")
                            .tint(SynapseTheme.accent)
                            .font(SynapseTheme.font(.body))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    } else if let report = viewModel.report {
                        dossierCard(title: "CONCEPTS MASTERED", list: report.conceptsMastered)
                        dossierCard(title: "AREAS FOR IMPROVEMENT", list: report.areasForImprovement)
                        dossierCard(title: "NEXT STEPS", list: report.nextSteps)
                        dossierCard(title: "RECOMMENDED VIDEO LINKS", list: report.recommendedVideoLinks)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("VISUAL MAP OF LEARNING")
                                .font(SynapseTheme.font(.headline))
                                .foregroundColor(SynapseTheme.accent)
                            
                            ForEach(report.visualMapNodes) { node in
                                DossierCard(title: node.title.uppercased()) {
                                    Text(node.description)
                                        .font(SynapseTheme.font(.caption))
                                        .foregroundColor(.gray)
                                    if let url = node.recommendedYoutubeUrl, let link = URL(string: url) {
                                        Link("OPEN DATALINK", destination: link)
                                            .font(SynapseTheme.font(.caption))
                                            .foregroundColor(SynapseTheme.accent)
                                    }
                                }
                            }
                        }
                        
                        if !viewModel.visualMapPrompt.isEmpty {
                            dossierCard(title: "DALLAS AI VISUAL BRIEF", body: viewModel.visualMapPrompt)
                        }
                    }
                    
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .font(SynapseTheme.font(.caption))
                            .foregroundColor(.red)
                    }
                    
                    TerminalButton(title: "ENTER THE FORGE") {
                        MissionStateManager.shared.enterForge()
                    }
                    .padding(.top, 8)
                }
                .padding(24)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.generateDebrief(for: session, didWin: session.outcome == .success)
        }
    }
    
    private func dossierCard(title: String, body: String) -> some View {
        DossierCard(title: title) {
            Text(body)
                .font(SynapseTheme.font(.body))
                .foregroundColor(.white)
        }
    }
    
    private func dossierCard(title: String, list: [String]) -> some View {
        dossierCard(title: title, body: list.isEmpty ? "NO ENTRIES" : list.joined(separator: "\n"))
    }
}

#Preview {
    DebriefView(session: GameSession(
        sessionId: "preview",
        playerA_Id: "a",
        playerB_Id: "b",
        trackTopic: "Prompt Engineering",
        isComplete: true,
        missionBrief: "Preview briefing",
        clues: ["One", "Two"],
        expectedAnswer: "Few-Shot Prompting",
        localAssignedRole: .controls,
        startedAt: Date(),
        durationSeconds: 900,
        outcome: .success,
        aiHintLog: []
    ))
}
