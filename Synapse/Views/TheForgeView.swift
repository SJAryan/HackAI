import SwiftUI

struct TheForgeView: View {
    @StateObject private var viewModel = ForgeViewModel()
    
    var body: some View {
        ZStack {
            SynapseTheme.background.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                Text("THE FORGE")
                    .font(SynapseTheme.font(.title2, weight: .black))
                    .fontWeight(.black)
                    .foregroundColor(.white)
                
                DossierCard(title: "COMMUNITY LAB") {
                    Text("Draft a new asymmetric mission prompt and publish it to the community Atlas collection.")
                        .font(SynapseTheme.font(.body))
                        .foregroundColor(.gray)
                }
                
                TextEditor(text: $viewModel.promptInput)
                    .font(SynapseTheme.font(.body))
                    .foregroundColor(.white)
                    .frame(height: 180)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(SynapseTheme.card)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(SynapseTheme.accent.opacity(0.25), lineWidth: 1))
                
                if let successMessage = viewModel.successMessage {
                    Text(successMessage)
                        .font(SynapseTheme.font(.caption))
                        .foregroundColor(SynapseTheme.accent)
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(SynapseTheme.font(.caption))
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                TerminalButton(
                    title: viewModel.isGenerating ? "FORGING MISSION..." : "SUBMIT TO MONGODB ATLAS",
                    isEnabled: !viewModel.promptInput.isEmpty && !viewModel.isGenerating
                ) {
                    viewModel.generateSkillModule()
                }
                
                Button(action: {
                    MissionStateManager.shared.restart()
                }) {
                    Text("RESTART DOSSIER FLOW")
                        .font(SynapseTheme.font(.caption))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(24)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    TheForgeView()
}
