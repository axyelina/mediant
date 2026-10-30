import Foundation
import FirebaseCore

/// Crash reports through Firebase Crashlytics. The only place that imports Firebase.
/// No Analytics: the app sends crashes, nothing about what the user does or sees.
enum CrashReporting {
    static func start() {
        // Unit tests run inside the app; keep them off the network.
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        FirebaseApp.configure()
    }
}
