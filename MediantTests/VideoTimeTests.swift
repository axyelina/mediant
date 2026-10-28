import Foundation
import Testing
@testable import Mediant

struct VideoTimeTests {
    @Test func formatsMinutesAndSeconds() {
        #expect(VideoTime.string(0) == "0:00")
        #expect(VideoTime.string(32) == "0:32")
        #expect(VideoTime.string(65.4) == "1:05")
        #expect(VideoTime.string(599.6) == "10:00")
    }

    @Test func formatsHours() {
        #expect(VideoTime.string(3_723) == "1:02:03")
    }

    @Test func negativeOrBrokenTimeShowsZero() {
        #expect(VideoTime.string(-3) == "0:00")
        #expect(VideoTime.string(.nan) == "0:00")
    }

    @Test func scrubMovesInProportionToTheDrag() {
        // A drag across the whole width covers the whole video.
        #expect(VideoTime.scrubbed(from: 10, by: 75, width: 300, duration: 40) == 20)
        #expect(VideoTime.scrubbed(from: 10, by: -150, width: 300, duration: 40) == 0)
    }

    @Test func scrubStaysInsideTheVideo() {
        #expect(VideoTime.scrubbed(from: 30, by: 300, width: 300, duration: 40) == 40)
        #expect(VideoTime.scrubbed(from: 5, by: -300, width: 300, duration: 40) == 0)
        #expect(VideoTime.scrubbed(from: 0, by: 50, width: 300, duration: 0) == 0)
    }
}
