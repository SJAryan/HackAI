import Foundation

enum AppRuntime {
    static let demoModeKey = "DEMO_MODE"
    static let networkTimeoutSeconds: Double = 8
    
    static var isDemoMode: Bool {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: demoModeKey) == nil {
            defaults.set(true, forKey: demoModeKey)
        }
        return defaults.bool(forKey: demoModeKey)
    }
}

enum AppRuntimeError: Error {
    case timedOut
}

func withTimeout<T>(
    seconds: Double = AppRuntime.networkTimeoutSeconds,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            let delay = UInt64(seconds * 1_000_000_000)
            try await Task.sleep(nanoseconds: delay)
            throw AppRuntimeError.timedOut
        }
        
        guard let result = try await group.next() else {
            throw AppRuntimeError.timedOut
        }
        group.cancelAll()
        return result
    }
}
