import SwiftUI

struct ProfileDebriefView: View {
    @StateObject private var viewModel = ProfileDebriefViewModel()
    let session: GameSession
    
    private let bgColor = Color(red: 0.05, green: 0.05, blue: 0.08)
    private let accentColor = Color(red: 0.0, green: 0.8, blue: 0.4)
    private let cardColor = Color(red: 0.1, green: 0.1, blue: 0.15)
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Intro Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("POST-MISSION ANALYSIS")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(accentColor)
                        Text("Gemini has analyzed your 15-minute sync telemetry and synchronized performance with your partner.")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                    
                    HStack {
                        Text("MISSION DEBRIEF")
                            .font(.system(.title2, design: .monospaced))
                            .fontWeight(.black)
                            .foregroundColor(.white)
                            .kerning(2)
                        
                        Spacer()
                        
                        if let mastery = viewModel.session?.peerMastery {
                            HStack(spacing: 2) {
                                ForEach(0..<5) { i in
                                    Image(systemName: "star.fill")
                                        .foregroundColor(i < mastery ? accentColor : .gray.opacity(0.3))
                                }
                            }
                        }
                    }
                    
                    if let report = viewModel.report {
                        HStack {
                            VStack {
                                Text("COMMS SCORE")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.gray)
                                Text("\(report.communicationScore)")
                                    .font(.system(.title, design: .monospaced))
                                    .foregroundColor(accentColor)
                            }
                            Spacer()
                            VStack {
                                Text("TIME ELAPSED")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.gray)
                                Text("12:30")
                                    .font(.system(.title, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(cardColor)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentColor.opacity(0.3), lineWidth: 1))
                        
                        Text("COGNITIVE MAP: NEXT STEPS")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.top)
                        
                        ForEach(report.visualMapNodes) { node in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(node.title.uppercased())
                                    .font(.system(.subheadline, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(accentColor)
                                
                                Text(node.description)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.gray)
                                
                                if let url = node.recommendedYoutubeUrl {
                                    Link("ACCESS DATALINK HUB", destination: URL(string: url)!)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(accentColor)
                                        .underline()
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(cardColor)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        }
                        
                        // Continue to Forge button
                        Button(action: {
                            withAnimation {
                                MissionStateManager.shared.enterForge()
                            }
                        }) {
                            Text("CONTINUE TO THE FORGE")
                                .font(.system(.headline, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(accentColor)
                                .cornerRadius(8)
                        }
                        .padding(.top, 20)
                        
                    } else if viewModel.isLoadingDebrief {
                        ProgressView("Analyzing mission telemetry via Gemini...")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(accentColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Button(action: {
                            viewModel.generateDebrief(for: session)
                        }) {
                            Text("GENERATE OPERATIVE DEBRIEF")
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
                }
                .padding(24)
            }
        }
        .onAppear {
            viewModel.generateDebrief(for: session)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ProfileDebriefView(session: GameSession(id: "1", topic: "Intro to AI", playerAId: "a", playerBId: "b", startTime: Date(), isActive: false, currentLevel: 3, clues: [], expectedAnswer: "", peerMastery: 4))
}
