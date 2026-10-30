import Foundation
import Testing
@testable import Mediant

/// In-memory notification center for unit tests.
final class FakeNotificationCenter: NotificationCenterClient, @unchecked Sendable {
    var status: NotificationPermission = .notDetermined
    var grants = true
    private(set) var requests = 0
    private(set) var scheduled: [String: (title: String, body: String, delay: TimeInterval)] = [:]

    func permission() async -> NotificationPermission { status }

    func requestPermission() async -> Bool {
        requests += 1
        status = grants ? .allowed : .denied
        return grants
    }

    func schedule(id: String, title: String, body: String, after delay: TimeInterval) async {
        scheduled[id] = (title, body, delay)
    }

    func cancel(id: String) { scheduled[id] = nil }
    func setTapHandler(_ handler: @escaping @MainActor @Sendable () -> Void) {}
}

@MainActor
struct TrashReminderTests {
    let center = FakeNotificationCenter()
    let defaults = UserDefaults(suiteName: "reminder-\(UUID().uuidString)")!
    var now = Date(timeIntervalSince1970: 1_000_000)

    func makeReminder(delay: TimeInterval = 7200) -> TrashReminder {
        TrashReminder(center: center, defaults: defaults, delay: delay, now: { [now] in now })
    }

    @Test func leavingWithAFullTrashSchedulesOneReminder() async {
        center.status = .allowed
        let reminder = makeReminder()
        await reminder.appLeft(trash: ["a", "b"], title: "Median't", body: "2 photos")
        #expect(center.scheduled[TrashReminder.id]?.body == "2 photos")
        #expect(center.scheduled[TrashReminder.id]?.delay == 7200)
        #expect(center.scheduled.count == 1)
    }

    @Test func leavingWithAnEmptyTrashSchedulesNothing() async {
        center.status = .allowed
        await makeReminder().appLeft(trash: [], title: "t", body: "b")
        #expect(center.scheduled.isEmpty)
    }

    @Test func withoutPermissionNothingIsScheduled() async {
        center.status = .denied
        await makeReminder().appLeft(trash: ["a"], title: "t", body: "b")
        #expect(center.scheduled.isEmpty)
    }

    @Test func switchedOffInTheAppNothingIsScheduled() async {
        center.status = .allowed
        let reminder = makeReminder()
        reminder.isEnabled = false
        await reminder.appLeft(trash: ["a"], title: "t", body: "b")
        #expect(center.scheduled.isEmpty)
        #expect(!makeReminder().isEnabled)
    }

    @Test func comingBackCancelsIt() async {
        center.status = .allowed
        let reminder = makeReminder()
        await reminder.appLeft(trash: ["a"], title: "t", body: "b")
        reminder.appCameBack()
        #expect(center.scheduled.isEmpty)
    }

    @Test func switchingOffCancelsAPendingOne() async {
        center.status = .allowed
        let reminder = makeReminder()
        await reminder.appLeft(trash: ["a"], title: "t", body: "b")
        reminder.isEnabled = false
        #expect(center.scheduled.isEmpty)
    }

    @Test func sameTrashIsNotRemindedTwice() async {
        // No nag: once a reminder went out for these photos, leaving again stays quiet.
        center.status = .allowed
        var clock = now
        let reminder = TrashReminder(center: center, defaults: defaults, delay: 7200, now: { clock })
        await reminder.appLeft(trash: ["a", "b"], title: "t", body: "b")
        clock = now.addingTimeInterval(7300)
        reminder.appCameBack()
        await reminder.appLeft(trash: ["b", "a"], title: "t", body: "b")
        #expect(center.scheduled.isEmpty)
    }

    @Test func changedTrashIsRemindedAgain() async {
        center.status = .allowed
        var clock = now
        let reminder = TrashReminder(center: center, defaults: defaults, delay: 7200, now: { clock })
        await reminder.appLeft(trash: ["a"], title: "t", body: "b")
        clock = now.addingTimeInterval(7300)
        reminder.appCameBack()
        await reminder.appLeft(trash: ["a", "c"], title: "t", body: "b")
        #expect(center.scheduled.count == 1)
    }

    @Test func comingBackEarlyMeansItNeverWentOut() async {
        center.status = .allowed
        var clock = now
        let reminder = TrashReminder(center: center, defaults: defaults, delay: 7200, now: { clock })
        await reminder.appLeft(trash: ["a"], title: "t", body: "b")
        clock = now.addingTimeInterval(60)
        reminder.appCameBack()
        await reminder.appLeft(trash: ["a"], title: "t", body: "b")
        #expect(center.scheduled.count == 1)
    }

    @Test func firstTrashOpenWithPhotosAsksOnce() async {
        let reminder = makeReminder()
        await reminder.trashOpened(count: 0)
        #expect(center.requests == 0)
        await reminder.trashOpened(count: 3)
        #expect(center.requests == 1)
        await reminder.trashOpened(count: 3)
        #expect(center.requests == 1)
        #expect(reminder.permission == .allowed)
    }

    @Test func switchedOffItNeverAsks() async {
        let reminder = makeReminder()
        reminder.isEnabled = false
        await reminder.trashOpened(count: 3)
        #expect(center.requests == 0)
    }

    @Test func turningOnAsksWhenIOSHasNotBeenAsked() async {
        let reminder = makeReminder()
        reminder.isEnabled = false
        await reminder.turnOn()
        #expect(reminder.isEnabled)
        #expect(center.requests == 1)
    }

    @Test func refreshReadsThePermission() async {
        center.status = .denied
        let reminder = makeReminder()
        await reminder.refreshPermission()
        #expect(reminder.permission == .denied)
    }
}
