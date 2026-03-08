import Foundation

enum DemoDataFactory {
    static func dossier(id: String = UUID().uuidString) -> UserDossier {
        UserDossier(
            id: id,
            currentSkills: ["SwiftUI", "Product Strategy", "Prompt Design", "APIs"],
            futureInterests: ["AI Safety", "Prompt Engineering", "Backend Systems"],
            suggestedRole: "Product Systems Operative",
            trackMastery: 3
        )
    }
    
    static func matchResponse(for dossier: UserDossier) -> MatchmakerResponse {
        MatchmakerResponse(
            status: "success",
            message: "Target secured.",
            peerId: "SIM-OPERATIVE-042",
            peerRole: "Backend Engineering",
            peerSummary: "Role: Backend Engineering. Skills: Node.js, MongoDB Atlas, WebSockets, API Design. Interests: AI Safety, Prompt Engineering.",
            trackTopic: dossier.futureInterests.first ?? "Prompt Engineering",
            matchScore: 0.93
        )
    }
    
    static func mission(for dossier: UserDossier, assignedRole: OperativeRole = .controls) -> GameSession {
        let topic = dossier.futureInterests.first ?? "Prompt Engineering"
        return GameSession(
            sessionId: UUID().uuidString,
            playerA_Id: dossier.id,
            playerB_Id: "SIM-OPERATIVE-042",
            trackTopic: topic,
            isComplete: false,
            missionBrief: "An encrypted learning dossier has been split across two operatives. Intel holds the evidence trail. Controls must submit the exact concept before the 15-minute breach window closes.",
            clues: [
                "The model is easier to steer when you demonstrate the desired pattern.",
                "Examples inside the prompt reduce ambiguity and shape the output format.",
                "The technique is named after how many examples you provide.",
                "It sits between zero-shot and many-example fine-tuning."
            ],
            expectedAnswer: "Few-Shot Prompting",
            localAssignedRole: assignedRole,
            startedAt: Date(),
            durationSeconds: 900,
            outcome: .pending,
            aiHintLog: [],
            peerMastery: 4,
            peerSuggestedRole: "Backend Engineering",
            peerSummary: "Systems-focused operative with strong retrieval and API instincts.",
            matchScore: 0.93
        )
    }
    
    static func debrief(for session: GameSession, didWin: Bool = true) -> DebriefReport {
        let links = [
            "https://www.youtube.com/watch?v=4Bdc55j80l8",
            "https://www.youtube.com/watch?v=dOxUroR57xs"
        ]
        return DebriefReport(
            sessionId: session.sessionId,
            userId: session.playerA_Id,
            communicationScore: didWin ? 91 : 76,
            completionTimeSeconds: max(300, session.durationSeconds - session.timeRemaining),
            conceptsMastered: [session.trackTopic, "Collaborative clue interpretation"],
            areasForImprovement: ["Faster answer commitment", "Sharper clue compression under time pressure"],
            nextSteps: [
                "Run a second mission with roles reversed.",
                "Practice converting hints into exact terminology.",
                "Watch one short explainer and summarize it back to a partner."
            ],
            recommendedVideoLinks: links,
            visualMapNodes: [
                LearningNode(
                    title: "Recovered Pattern",
                    description: "You identified the mission structure and mapped clues into a valid concept pathway.",
                    recommendedYoutubeUrl: links.first,
                    timestamp: "1m 40s"
                ),
                LearningNode(
                    title: "Next Breach Point",
                    description: "You can improve by committing to the final phrase earlier once the clue pattern is obvious.",
                    recommendedYoutubeUrl: links.last,
                    timestamp: "4m 20s"
                )
            ],
            dallasVisualPrompt: "Dark thriller-style dossier map with neon green path lines and monospaced annotations for mastered concepts and next steps."
        )
    }
    
    static func hint(for session: GameSession) -> String {
        "Think about the name of the prompting method implied by examples."
    }
}
