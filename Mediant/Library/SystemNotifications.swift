import UserNotifications

/// Local notifications through `UNUserNotificationCenter`. No server and no push entitlement.
final class SystemNotifications: NSObject, NotificationCenterClient, UNUserNotificationCenterDelegate,
                                 @unchecked Sendable {
    private var center: UNUserNotificationCenter { .current() }
    private var onTap: (@MainActor @Sendable () -> Void)?

    /// Set up while the app launches, so a tap that launched the app is not missed.
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func setTapHandler(_ handler: @escaping @MainActor @Sendable () -> Void) {
        onTap = handler
    }

    // Completion-handler forms, not `async`: an async delegate method runs off the main thread, and
    // UIKit then gets the completion call off the main thread too and stops the app (a tap crashed).
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        Self.deliverTap(onTap: onTap, completion: completionHandler)
    }

    /// Runs the tap handler, then iOS's completion, both on the main thread whatever thread iOS used.
    static func deliverTap(onTap: (@MainActor @Sendable () -> Void)?, completion: @escaping () -> Void) {
        let completion = UncheckedBox(completion)
        DispatchQueue.main.async {
            MainActor.assumeIsolated { onTap?() }
            completion.value()
        }
    }

    /// The reminder is cancelled while the app is open; anything left is not shown on top of it.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([])
    }

    func permission() async -> NotificationPermission {
        switch await center.notificationSettings().authorizationStatus {
        case .notDetermined: .notDetermined
        case .denied: .denied
        default: .allowed
        }
    }

    func requestPermission() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func schedule(id: String, title: String, body: String, after delay: TimeInterval) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(delay, 1), repeats: false)
        try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    func cancel(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.removeDeliveredNotifications(withIdentifiers: [id])
    }
}

/// iOS's completion handler is not marked Sendable; it is only called once, on the main thread.
private struct UncheckedBox<T>: @unchecked Sendable {
    let value: T
    init(_ value: T) { self.value = value }
}
