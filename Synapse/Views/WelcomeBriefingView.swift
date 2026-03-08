import SwiftUI

struct WelcomeBriefingView: View {
    private let bgColor = Color(red: 0.05, green: 0.05, blue: 0.08)
    private let accentColor = Color(red: 0.0, green: 0.8, blue: 0.4)
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "cpu")
                        .font(.system(size: 80))
                        .foregroundColor(accentColor)
                        .padding(.bottom, 10)
                    
                    Text("SYNAPSE: ASYMMETRIC")
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .kerning(2)
                    
                    Text("LEARNING TERMINAL")
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .kerning(2)
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("TACTICAL BRIEFING")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(accentColor)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        instructionRow(icon: "1.circle.fill", text: "UPLOAD DOSSIER: Input your resume. Gemini will extract your unique operative role.")
                        instructionRow(icon: "2.circle.fill", text: "VECTOR MATCH: We pair you with a complementary peer (e.g. Engineer + Manager).")
                        instructionRow(icon: "3.circle.fill", text: "ASYMMETRIC SYNC: One gets the Controls (input), one gets the Intel (clues). Must use voice comms to sync.")
                    }
                }
                .padding()
                .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        MissionStateManager.shared.startOnboarding()
                    }
                }) {
                    Text("ACKNOWLEDGE & BEGIN")
                        .font(.system(.headline, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(accentColor)
                        .cornerRadius(8)
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
                .foregroundColor(accentColor)
            Text(text)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.gray)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    WelcomeBriefingView()
}
