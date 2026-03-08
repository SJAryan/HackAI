import SwiftUI

struct WelcomeBriefingView: View {
    @ObservedObject private var missionState = MissionStateManager.shared
    
    var body: some View {
        ZStack {
            SynapseTheme.background.ignoresSafeArea()
            
            VStack(spacing: 40) {
                HStack {
                    StatusPill(text: missionState.demoMode ? "DEMO MODE ON" : "LIVE MODE", color: missionState.demoMode ? SynapseTheme.accent : .orange)
                    Spacer()
                    Button(action: {
                        missionState.toggleDemoMode()
                    }) {
                        Text("TOGGLE")
                            .font(SynapseTheme.font(.caption, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "cpu")
                        .font(.system(size: 80))
                        .foregroundColor(SynapseTheme.accent)
                        .padding(.bottom, 10)
                    
                    Text("SYNAPSE: ASYMMETRIC")
                        .font(SynapseTheme.font(.title2, weight: .black))
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .kerning(2)
                    
                    Text("LEARNING TERMINAL")
                        .font(SynapseTheme.font(.title2, weight: .black))
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .kerning(2)
                }
                
                DossierCard(title: "TACTICAL BRIEFING") {
                    VStack(alignment: .leading, spacing: 12) {
                        instructionRow(icon: "1.circle.fill", text: "UPLOAD DOSSIER: Input your resume. Gemini will extract your unique operative role.")
                        instructionRow(icon: "2.circle.fill", text: "VECTOR MATCH: We pair you with a complementary peer (e.g. Engineer + Manager).")
                        instructionRow(icon: "3.circle.fill", text: "ASYMMETRIC SYNC: One gets the Controls (input), one gets the Intel (clues). Must use voice comms to sync.")
                        if missionState.demoMode {
                            Text("DEMO SURVIVAL MODE: If venue Wi-Fi collapses, Synapse will silently switch to realistic local intelligence.")
                                .font(SynapseTheme.font(.caption))
                                .foregroundColor(.gray)
                                .padding(.top, 6)
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                TerminalButton(title: "ACKNOWLEDGE & BEGIN") {
                    withAnimation {
                        MissionStateManager.shared.startOnboarding()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func instructionRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(SynapseTheme.accent)
            Text(text)
                .font(SynapseTheme.font(.caption))
                .foregroundColor(.gray)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    WelcomeBriefingView()
}
