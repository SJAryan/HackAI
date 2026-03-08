import Foundation
import AgoraRtcKit
import Combine
import AVFoundation

class AgoraService: NSObject, ObservableObject {
    static let shared = AgoraService()
    
    // The App ID from your Agora Developer Console
    private let appID = "1d3233ea60744b588217027e979ab040"
    
    // The main Agora Engine instance
    private var agoraEngine: AgoraRtcEngineKit!
    
    @Published var isJoined = false
    @Published var permissionError: String? = nil
    
    private override init() {
        super.init()
        initializeAgoraEngine()
    }
    
    private func initializeAgoraEngine() {
        let config = AgoraRtcEngineConfig()
        config.appId = appID
        // We only need the Audio engine for this hackathon
        agoraEngine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
    }
    
    func joinChannel(channelName: String) {
        // First check if the user granted Microphone permissions
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.permissionError = nil
                    // Join the channel immediately. Since we chose "Testing Mode" in the console, 
                    // we can pass `nil` for the Token!
                    let mediaOptions = AgoraRtcChannelMediaOptions()
                    mediaOptions.publishMicrophoneTrack = true
                    mediaOptions.autoSubscribeAudio = true
                    
                    // We generate a random UID because we don't care about specific user ID tracking for voice
                    let randomUid = UInt.random(in: 1...9999)
                    
                    let result = self?.agoraEngine.joinChannel(
                        byToken: nil,
                        channelId: channelName,
                        uid: randomUid,
                        mediaOptions: mediaOptions
                    )
                    
                    if result == 0 {
                        print("Successfully called joinChannel")
                    } else {
                        print("Error joining channel, code: \(String(describing: result))")
                    }
                } else {
                    self?.permissionError = "Microphone access is required for co-op gameplay!"
                }
            }
        }
    }
    
    func leaveChannel() {
        agoraEngine.leaveChannel(nil)
        isJoined = false
    }
}

extension AgoraService: AgoraRtcEngineDelegate {
    // This callback confirms we actually connected to the Agora Server
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        DispatchQueue.main.async {
            self.isJoined = true
            print("Successfully joined voice channel: \(channel)")
        }
    }
    
    // This callback tells us when our partner joins the voice channel!
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("Partner (UID: \(uid)) joined the voice channel!")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        print("Partner (UID: \(uid)) left the voice channel.")
    }
}
