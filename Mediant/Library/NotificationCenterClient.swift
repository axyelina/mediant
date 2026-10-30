import Foundation

enum NotificationPermission {
    case notDetermined, allowed, denied
}

/// The app's view of local notifications. UserNotifications lives behind it so the reminder logic
/// can be tested with a fake.
protocol NotificationCenterClient: AnyObject, Sendable {
    func permission() async -> NotificationPermission
    /// Shows the iOS permission dialog (only the first time). Returns whether it is allowed.
    func requestPermission() async -> Bool
    /// Replaces any pending notification with the same id.
    func schedule(id: String, title: String, body: String, after delay: TimeInterval) async
    func cancel(id: String)
    /// Called on the main actor when the user taps a delivered notification.
    func setTapHandler(_ handler: @escaping @MainActor @Sendable () -> Void)
}
