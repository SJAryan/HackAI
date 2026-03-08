import SwiftUI

enum SynapseTheme {
    static let background = Color(red: 0.05, green: 0.05, blue: 0.07)
    static let card = Color(red: 0.10, green: 0.10, blue: 0.15)
    static let accent = Color(red: 0.29, green: 0.87, blue: 0.50)
    static let intel = Color(red: 0.0, green: 0.6, blue: 1.0)
    static let secondaryText = Color.gray
    
    static func font(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .monospaced, weight: weight)
    }
}

struct DossierCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(SynapseTheme.font(.caption))
                .foregroundColor(SynapseTheme.accent)
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SynapseTheme.card)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(SynapseTheme.accent.opacity(0.25), lineWidth: 1)
        )
    }
}

struct TerminalButton: View {
    let title: String
    var isEnabled: Bool = true
    var accent: Color = SynapseTheme.accent
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(SynapseTheme.font(.headline, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isEnabled ? accent : Color.gray)
                .cornerRadius(10)
        }
        .disabled(!isEnabled)
    }
}

struct StatusPill: View {
    let text: String
    var color: Color = SynapseTheme.accent
    
    var body: some View {
        Text(text)
            .font(SynapseTheme.font(.caption2, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.35), lineWidth: 1)
            )
    }
}
