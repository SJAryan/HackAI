import Foundation
import Starscream

class WebSocketService: ObservableObject {
    static let shared = WebSocketService()
    var socket: WebSocket?
    
    @Published var isConnected = false
    @Published var activeClueIndex: Int? = nil
    @Published var lastAttemptedAnswer: String? = nil
    
    // Replace with your actual backend URL when deploying
    private let serverURL = "ws://localhost:3000"
    
    private init() {}
    
    func connect() {
        guard let url = URL(string: serverURL) else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
    }
    
    func joinGameSession(sessionId: String, userId: String) {
        // Socket.io sends events as a JSON array: ["eventName", payloadObject]
        let payload: [String: Any] = ["sessionId": sessionId, "userId": userId]
        emit(event: "joinRoom", payload: payload)
    }
    
    func revealClue(sessionId: String, clueIndex: Int) {
        let payload: [String: Any] = ["sessionId": sessionId, "clueIndex": clueIndex]
        emit(event: "revealClue", payload: payload)
    }
    
    func submitAnswer(sessionId: String, answer: String) {
        let payload: [String: Any] = ["sessionId": sessionId, "answer": answer]
        emit(event: "submitAnswer", payload: payload)
    }
    
    private func emit(event: String, payload: [String: Any]) {
        // Construct the Socket.io message format
        let messageArray: [Any] = [event, payload]
        if let jsonData = try? JSONSerialization.data(withJSONObject: messageArray),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            // Socket.io v4 messages start with "42"
            let socketMessage = "42" + jsonString
            socket?.write(string: socketMessage)
        }
    }
}

extension WebSocketService: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected(let headers):
            DispatchQueue.main.async {
                self.isConnected = true
                print("WebSocket Connected: \(headers)")
            }
        case .disconnected(let reason, let code):
            DispatchQueue.main.async {
                self.isConnected = false
                print("WebSocket Disconnected: \(reason) with code: \(code)")
            }
        case .text(let string):
            handleIncomingMessage(string)
        case .error(let error):
            print("WebSocket Error: \(String(describing: error))")
        default:
            break
        }
    }
    
    private func handleIncomingMessage(_ message: String) {
        // Ignore Engine.io protocol messages (like "0" for open or "2" for ping)
        guard message.hasPrefix("42") else { return }
        
        // Strip the "42" prefix to parse the JSON array payload
        let jsonString = String(message.dropFirst(2))
        guard let data = jsonString.data(using: .utf8),
              let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [Any],
              jsonArray.count >= 2,
              let eventName = jsonArray[0] as? String,
              let payload = jsonArray[1] as? [String: Any] else {
            return
        }
        
        DispatchQueue.main.async {
            switch eventName {
            case "clueRevealed":
                if let index = payload["clueIndex"] as? Int {
                    self.activeClueIndex = index
                }
            case "answerAttempted":
                if let answer = payload["answer"] as? String {
                    self.lastAttemptedAnswer = answer
                }
            default:
                break
            }
        }
    }
}
