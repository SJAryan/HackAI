import SwiftUI

struct ForgeView: View {
    @StateObject private var viewModel = ForgeViewModel()
    
    private let bgColor = Color(red: 0.05, green: 0.05, blue: 0.08)
    private let accentColor = Color(red: 0.0, green: 0.8, blue: 0.4)
    private let cardColor = Color(red: 0.1, green: 0.1, blue: 0.15)
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // NEW: Intro Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("THE FORGE: AI ARCHITECT")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(accentColor)
                    Text("Use the power of Gemini to dynamically generate new asymmetric training modules for the community based on any topic.")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)

                Text("MODULE SYNTHESIS")
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .kerning(2)
                
                Text(viewModel.isGenerating ? "Gemini is synthesizing your module..." : "Input a topic to generate a new asymmetric learning module.")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextEditor(text: $viewModel.promptInput)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(height: 150)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(cardColor)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(accentColor.opacity(0.3), lineWidth: 1)
                    )
                
                if let message = viewModel.successMessage {
                    Text(message)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(accentColor)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: {
                        viewModel.generateSkillModule()
                    }) {
                        Text(viewModel.isGenerating ? "FORGING..." : "SUBMIT TO DATABASE")
                            .font(.system(.headline, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.isGenerating || viewModel.promptInput.isEmpty ? Color.gray : accentColor)
                            .cornerRadius(8)
                    }
                    .disabled(viewModel.isGenerating || viewModel.promptInput.isEmpty)
                    
                    Button(action: {
                        withAnimation {
                            MissionStateManager.shared.restart()
                        }
                    }) {
                        Text("RESTART PROTOCOL")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(24)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ForgeView()
}
