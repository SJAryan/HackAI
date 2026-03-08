import SwiftUI

struct ActiveMissionView: View {
    @StateObject var viewModel: ActiveMissionViewModel
    
    private let bgColor = Color(red: 0.05, green: 0.05, blue: 0.08)
    private let accentColor = Color(red: 0.0, green: 0.8, blue: 0.4)
    private let intelColor = Color(red: 0.0, green: 0.6, blue: 1.0)
    private let cardColor = Color(red: 0.1, green: 0.1, blue: 0.15)
    
    @State private var timeRemaining = 900 // 15 mins
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ACTIVE MISSION")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.gray)
                        Text(viewModel.session.trackTopic.uppercased())
                            .font(.system(.title3, design: .monospaced))
                            .fontWeight(.black)
                            .foregroundColor(.white)
                        Text(viewModel.missionStatusLine)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(accentColor)
                    }
                    
                    Spacer()
                    
                    let minutes = timeRemaining / 60
                    let seconds = timeRemaining % 60
                    Text(String(format: "%02d:%02d", minutes, seconds))
                        .font(.system(size: 34, weight: .black, design: .monospaced))
                        .foregroundColor(timeRemaining < 300 ? .red : accentColor)
                        .onReceive(timer) { _ in
                            if timeRemaining > 0 {
                                timeRemaining -= 1
                            }
                        }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("MISSION BRIEF")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)
                    Text(viewModel.session.missionBrief.isEmpty ? "Coordinate under pressure. Intel owns the clues. Controls owns the final submission." : viewModel.session.missionBrief)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(cardColor)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentColor.opacity(0.25), lineWidth: 1))
                .padding(.horizontal, 20)
                
                HStack {
                    Text("LOCAL ROLE")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)
                    Text(viewModel.isPlayerA ? "CONTROLS" : "INTEL")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(viewModel.isPlayerA ? accentColor : intelColor)
                    Spacer()
                }
                .padding(.horizontal, 20)
                
                Divider().background(Color.gray.opacity(0.3))
                
                if viewModel.isPlayerA {
                    controlsPanel
                } else {
                    intelPanel
                }
                
                VStack(spacing: 12) {
                    Button(action: {
                        viewModel.requestHintFromGameMaster()
                    }) {
                        Text("REQUEST AI HINT")
                            .font(.system(.headline, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.85))
                            .cornerRadius(10)
                    }
                    
                    if viewModel.isPlayerA {
                        Button(action: {
                            viewModel.submitAnswer()
                            MissionStateManager.shared.completeMission(session: viewModel.session)
                        }) {
                            Text("EXECUTE / SUBMIT")
                                .font(.system(.headline, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(accentColor)
                                .cornerRadius(10)
                        }
                    } else {
                        Button(action: {
                            viewModel.terminateMission()
                            MissionStateManager.shared.completeMission(session: viewModel.session)
                        }) {
                            Text("EXECUTE / END SESSION")
                                .font(.system(.headline, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.85))
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                if !viewModel.hintMessage.isEmpty {
                    Text("SYSTEM OVERRIDE: \(viewModel.hintMessage)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            timeRemaining = viewModel.session.durationSeconds
        }
    }
    
    private var controlsPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CONTROLS TERMINAL")
                .font(.system(.headline, design: .monospaced))
                .foregroundColor(accentColor)
            
            Text("Receive Intel transmissions, translate them into the exact target phrase, then submit.")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.gray)
            
            TextEditor(text: $viewModel.answerInput)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(accentColor)
                .frame(height: 140)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(cardColor)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(accentColor.opacity(0.3), lineWidth: 1))
            
            Text("EXPECTED OUTPUT FORMAT: exact phrase only")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 20)
    }
    
    private var intelPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("INTEL DOSSIER")
                .font(.system(.headline, design: .monospaced))
                .foregroundColor(intelColor)
            
            Text("Transmit clues in sequence. Do not reveal the answer directly unless the clock forces it.")
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
                .cornerRadius(10)
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    ActiveMissionView(viewModel: ActiveMissionViewModel(session: GameSession(
        sessionId: "test",
        playerA_Id: "kevin_123",
        playerB_Id: "peer_007",
        trackTopic: "SwiftUI UI Rendering",
        isComplete: false,
        missionBrief: "One operative interprets the interface evidence while the other submits the exact answer.",
        clues: ["Uses parentheses", "Outputs to console"],
        expectedAnswer: "print",
        localAssignedRole: .controls,
        startedAt: Date(),
        durationSeconds: 900,
        outcome: .pending,
        aiHintLog: [],
        peerMastery: 5
    )))
}
