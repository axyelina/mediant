import Foundation
import Testing
@testable import Mediant

struct SystemNotificationsTests {
    /// iOS may deliver a tap off the main thread; the handler and the completion must run on it.
    @Test func tapAndCompletionRunOnTheMainThread() async {
        let result = await withCheckedContinuation { (continuation: CheckedContinuation<(Bool, Bool), Never>) in
            DispatchQueue.global().async {
                let tapOnMain = Box()
                SystemNotifications.deliverTap(onTap: { tapOnMain.value = Thread.isMainThread }) {
                    continuation.resume(returning: (tapOnMain.value, Thread.isMainThread))
                }
            }
        }
        #expect(result.0)
        #expect(result.1)
    }

    private final class Box: @unchecked Sendable { var value = false }
}
