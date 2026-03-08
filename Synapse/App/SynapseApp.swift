import SwiftUI

@main
struct SynapseApp: App {
    @ObservedObject private var stateManager = MissionStateManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch stateManager.currentPhase {
                case .welcome:
                    WelcomeBriefingView()
                case .onboarding:
                    OnboardingView()
                case .activeMission(let session):
                    ActiveMissionView(viewModel: ActiveMissionViewModel(session: session))
                case .debrief(let session):
                    DebriefView(session: session)
                case .forge:
                    TheForgeView()
                }
            }
        }
    }
}
