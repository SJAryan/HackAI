import SwiftUI

enum MissionPhase {
    case welcome
    case onboarding
    case activeMission(session: GameSession)
    case debrief(session: GameSession)
    case forge
}

@MainActor
class MissionStateManager: ObservableObject {
    static let shared = MissionStateManager()
    
    @Published var currentPhase: MissionPhase = .welcome
    @AppStorage("hasSeenBriefing") private var hasSeenBriefing = false
    @AppStorage(AppRuntime.demoModeKey) var demoMode = true
    
    private init() {
        if hasSeenBriefing {
            currentPhase = .onboarding
        }
    }
    
    func startOnboarding() {
        hasSeenBriefing = true
        currentPhase = .onboarding
    }
    
    func enterMission(session: GameSession) {
        currentPhase = .activeMission(session: session)
    }
    
    func completeMission(session: GameSession) {
        currentPhase = .debrief(session: session)
    }
    
    func enterForge() {
        currentPhase = .forge
    }
    
    func restart() {
        currentPhase = .onboarding
    }
    
    func toggleDemoMode() {
        demoMode.toggle()
    }
}
