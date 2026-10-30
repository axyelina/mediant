import Foundation
import Observation

/// One local reminder for a forgotten Trash: leaving the app with photos in the Trash schedules it
/// (`delay` later); coming back cancels it. The text is fixed when it is scheduled, because the app
/// does not run when it fires. The same Trash is reminded only once, so it never nags.
@MainActor
@Observable
final class TrashReminder {
    static let id = "trash-reminder"
    /// Debug builds use a short delay, so the reminder can be tried on a phone.
    #if DEBUG
    nonisolated static let defaultDelay: TimeInterval = 30
    #else
    nonisolated static let defaultDelay: TimeInterval = 2 * 60 * 60
    #endif

    private static let enabledKey = "trashReminderEnabled"
    private static let askedKey = "trashReminderAsked"
    private static let remindedKey = "trashReminderReminded"
    private static let pendingKey = "trashReminderPending"
    private static let fireDateKey = "trashReminderFireDate"

    /// The app's own switch (Settings); on by default.
    var isEnabled: Bool {
        didSet {
            defaults.set(isEnabled, forKey: Self.enabledKey)
            if !isEnabled { cancel() }
        }
    }
    /// The iOS permission, as last read.
    private(set) var permission: NotificationPermission = .notDetermined

    private let center: NotificationCenterClient
    private let defaults: UserDefaults
    private let delay: TimeInterval
    private let now: () -> Date

    init(center: NotificationCenterClient, defaults: UserDefaults = .standard,
         delay: TimeInterval = TrashReminder.defaultDelay, now: @escaping () -> Date = Date.init) {
        self.center = center
        self.defaults = defaults
        self.delay = delay
        self.now = now
        isEnabled = defaults.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    func refreshPermission() async {
        permission = await center.permission()
    }

    /// The first time the Trash tab opens with photos in it, iOS asks for permission once.
    func trashOpened(count: Int) async {
        guard isEnabled, count > 0, !defaults.bool(forKey: Self.askedKey) else { return }
        await ask()
    }

    /// The Settings switch: on, and ask iOS if it has never been asked.
    func turnOn() async {
        isEnabled = true
        await refreshPermission()
        if permission == .notDetermined { await ask() }
    }

    func appLeft(trash ids: [String], title: String, body: String) async {
        guard isEnabled, !ids.isEmpty else { return }
        await refreshPermission()
        let signature = Self.signature(ids)
        guard permission == .allowed, signature != defaults.string(forKey: Self.remindedKey) else { return }
        await center.schedule(id: Self.id, title: title, body: body, after: delay)
        defaults.set(signature, forKey: Self.pendingKey)
        defaults.set(now().addingTimeInterval(delay), forKey: Self.fireDateKey)
    }

    /// Cancels a pending reminder. If it already went out, remembers its Trash so it is not repeated.
    func appCameBack() {
        if let pending = defaults.string(forKey: Self.pendingKey),
           let fireDate = defaults.object(forKey: Self.fireDateKey) as? Date, now() >= fireDate {
            defaults.set(pending, forKey: Self.remindedKey)
        }
        cancel()
    }

    private func ask() async {
        defaults.set(true, forKey: Self.askedKey)
        _ = await center.requestPermission()
        await refreshPermission()
    }

    private func cancel() {
        center.cancel(id: Self.id)
        defaults.removeObject(forKey: Self.pendingKey)
        defaults.removeObject(forKey: Self.fireDateKey)
    }

    private static func signature(_ ids: [String]) -> String {
        ids.sorted().joined(separator: "|")
    }
}
