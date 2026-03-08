import SwiftUI

struct ProfileDebriefView: View {
    let session: GameSession
    
    var body: some View {
        DebriefView(session: session)
    }
}

#Preview {
    ProfileDebriefView(session: GameSession(id: "1", topic: "Intro to AI", playerAId: "a", playerBId: "b", startTime: Date(), isActive: false, currentLevel: 3, clues: [], expectedAnswer: "", peerMastery: 4))
}
