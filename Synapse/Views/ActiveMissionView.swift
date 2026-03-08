import SwiftUI

struct ActiveMissionView: View {
    @StateObject var viewModel: ActiveMissionViewModel
    
    // UI Constants
    private let bgColor = Color(red: 0.05, green: 0.05, blue: 0.08)
    private let accentColor = Color(red: 0.0, green: 0.8, blue: 0.4)
    private let intelColor = Color(red: 0.0, green: 0.6, blue: 1.0)
    private let cardColor = Color(red: 0.1, green: 0.1, blue: 0.15)
    
    // Timer Scaffold
    @State private var timeRemaining = 900 // 15 mins
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            VStack(spacing: 20) {
                    
                    // Header Status
                    HStack {
                        VStack(alignment: .leading) {
                            Text("ACTIVE MISSION")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.gray)
                            Text(viewModel.session.topic.uppercased())
                                .font(.system(.title3, design: .monospaced))
                                .fontWeight(.black)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        // Live Countdown
                        let minutes = timeRemaining / 60
                        let seconds = timeRemaining % 60
                        Text(String(format: "%02d:%02d", minutes, seconds))
                            .font(.system(size: 32, weight: .black, design: .monospaced))
                            .foregroundColor(timeRemaining < 300 ? .red : accentColor)
                            .onReceive(timer) { _ in
                                if timeRemaining > 0 {
                                    timeRemaining -= 1
                                }
                            }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Role Indicator
                    HStack {
                        Text("ASSIGNED ROLE:")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.gray)
                        Text(viewModel.isPlayerA ? "CONTROLS" : "INTEL")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(viewModel.isPlayerA ? accentColor : intelColor)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    // Split Layout
                    if viewModel.isPlayerA {
                        // CONTROLS VIEW
                        VStack(alignment: .leading, spacing: 16) {
                            // NEW: Instructions
                            VStack(alignment: .leading, spacing: 8) {
                                Text("OPERATIVE INSTRUCTIONS: CONTROLS")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(accentColor)
                                Text("1. Listen to your partner's Intel. 2. Identify the target function. 3. Type the exact command below and EXECUTE.")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)

                            Text("EXECUTION TERMINAL")
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundColor(accentColor)
                            
                            Text("Awaiting Intel clues. Bypass the security firewall using the acquired target function.")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.gray)
                            
                            TextEditor(text: $viewModel.answerInput)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(accentColor)
                                .frame(height: 120)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                                .background(cardColor)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(accentColor.opacity(0.3), lineWidth: 1))
                            
                            Spacer()
                            
                            Button(action: {
                                viewModel.submitAnswer()
                                withAnimation {
                                    MissionStateManager.shared.completeMission(session: viewModel.session)
                                }
                            }) {
                                Text("EXECUTE OVERRIDE")
                                    .font(.system(.headline, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(accentColor)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(20)
                        
                    } else {
                        // INTEL VIEW
                        VStack(alignment: .leading, spacing: 16) {
                            // NEW: Instructions
                            VStack(alignment: .leading, spacing: 8) {
                                Text("OPERATIVE INSTRUCTIONS: INTEL")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(intelColor)
                                Text("1. Read retrieved data below. 2. Use Agora voice channel to guide Controls. 3. Transmit clues sequentially.")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)

                            Text("CLASSIFIED INTEL ARCHIVE")
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundColor(intelColor)
                            
                            Text("Guide the Controls operative. Reveal clues sequentially.")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.gray)
                            
                            ScrollView {
                                VStack(spacing: 12) {
                                    ForEach(0..<viewModel.revealedCluesCount, id: \.self) { index in
                                        if index < viewModel.session.clues.count {
                                            HStack(alignment: .top) {
                                                Text("[\(index + 1)]")
                                                    .foregroundColor(intelColor)
                                                    .font(.system(.subheadline, design: .monospaced))
                                                Text(viewModel.session.clues[index])
                                                    .font(.system(.subheadline, design: .monospaced))
                                                    .foregroundColor(.white)
                                                Spacer()
                                            }
                                            .padding()
                                            .background(cardColor)
                                            .cornerRadius(8)
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(intelColor.opacity(0.3), lineWidth: 1))
                                        }
                                    }
                                }
                            }
                            
                            if viewModel.revealedCluesCount < viewModel.session.clues.count {
                                Button("TRANSMIT NEXT CLUE") {
                                    viewModel.revealNextClue()
                                }
                                .font(.system(.headline, design: .monospaced))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(intelColor)
                                .cornerRadius(8)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    MissionStateManager.shared.completeMission(session: viewModel.session)
                                }
                            }) {
                                Text("TERMINATE SESSION")
                                    .font(.system(.headline, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red.opacity(0.8))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(20)
                    }
                    
                    if !viewModel.hintMessage.isEmpty {
                        Text("SYSTEM OVERRIDE: \(viewModel.hintMessage)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.yellow)
                            .padding(.bottom, 20)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ActiveMissionView(viewModel: ActiveMissionViewModel(session: GameSession(id: "test", topic: "SwiftUI UI Rendering", playerAId: "kevin_123", playerBId: "peer_007", startTime: Date(), isActive: true, currentLevel: 1, clues: ["Uses parentheses", "Outputs to console"], expectedAnswer: "print", peerMastery: 5)))
}
