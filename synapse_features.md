# Synapse: Hackathon Features Implemented 🚀

Here is a comprehensive overview of every feature built into the Synapse iOS App and Node.js Backend so far!

## 1. Operative Matchmaking (MongoDB Atlas Track) 🧬
- **"Silent Witness" Dossier UI:** A slick, high-stakes dual-phase onboarding flow replacing standard forms with a dark-mode intelligence aesthetic.
- **Gemini Structured Intelligence:** Swapped basic PDF extraction for `ResumeParserService`, which invokes Gemini 3.1 Flash with `application/json` output schemas to intelligently extract the user's "Current Skills" and "Target Interests".
- **Rich Profile Vectorization:** iOS concatenates explicit answers (Target Path, Mastery Rating) with the Gemini-parsed resume intelligence. The Node.js Express backend (`POST /match`) accepts this dense string and converts it into a 384-dimensional vector embedding.
- **Atlas Vector Search Pipeline:** We run an advanced `$vectorSearch` query against the `SynapseDB` database on MongoDB Atlas to find an online peer who shares high semantic similarity in Target Interests, but applies a strict filter to ensure complementary, differing primary roles.
- **Peer Mastery Overrides:** The UI features a manual baseline slider for mastery, which the backend saves and passes through natively for the end-of-game Debrief mapping.

## 2. The AI Game Master (Gemini API Track) 🧠
- **Gemini 3.1 Flash Integration:** Integrated `gemini-3.1-flash` via REST API inside `GeminiService.swift`.
- **Dynamic Asymmetric Puzzles:** The exact moment a peer match is made, the Game Master analyzes both players' bios and dynamically generates a structurally typed 15-minute asymmetric `GameSession` JSON puzzle.
- **In-Game Hint System:** Players stuck in the Active Mission lobby can ping the AI array. Gemini reads the specific topic and the clues revealed so far to return a personalized, cryptic hint.

## 3. Real-Time Gameplay & Comm (NRVE Track) ⚡
- **WebSocket Game State:** Instead of a static flow, the `ActiveMissionViewModel` uses Combine to listen to `socket.io` events from the Node server. Player A's screen dynamically reveals clues the exact millisecond Player B taps the button on their phone.
- **Live Voice Channels (Agora SDK):** Fully integrated the Agora WebRTC SDK. The app seamlessly requests microphone permissions and places both matched players into a secure, isolated Voice Channel named after their specific `GameSession` ID.

## 4. The Debrief (Dallas AI Track) 📊
- **JSON Structured Analytics:** When the mission timer ends or is answered correctly, the app POSTs the mission state to the `generateDebrief` API.
- **Personalized Action Plan:** Gemini acts as a Debrief Tutor, analyzing their performance to return a strictly typed `DebriefReport` containing "Concepts Mastered", "Areas for Improvement", and a creative Visual Map of Learning.
- **Custom YouTube Links:** The AI generates realistic YouTube video recommendations tailored exactly to the topic they struggled with during the match.

## 5. "The Forge" Community Lab (+Bonus Track) 🔨
- **Generative Module Creation:** Users can open the Forge tab and use natural language (e.g., "Build an asymmetric module on Quantum Computing"). Gemini instantly generates a new puzzle logic matching the `GameSession` schema.
- **Direct-to-Database Saving:** Once generated, the app sends the raw JSON straight to a new `POST /forge` endpoint on the Express server, permanently saving the community-forged module to the MongoDB Atlas `modules` collection.

## Application Architecture 🏗️
- **iOS Client:** 100% native SwiftUI following the MVVM protocol. Structured with Models (e.g., `GameSession`, `DebriefReport`), ViewModels (business logic and networking), and Views (`MatchmakerView`, `ActiveMissionView`, etc).
- **Node.js Backend:** Express.js `index.js` server managing the complex logic like `socket.io` streams, `<->` HuggingFace API integration, and direct MongoDB Atlas database operations.
