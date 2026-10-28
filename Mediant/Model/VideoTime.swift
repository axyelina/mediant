import Foundation

enum VideoTime {
    /// A video position or length like "0:32", "12:05" or "1:02:03", rounded to whole seconds.
    static func string(_ seconds: TimeInterval) -> String {
        let total = seconds.isFinite ? max(Int(seconds.rounded()), 0) : 0
        let (hours, minutes, secs) = (total / 3600, total / 60 % 60, total % 60)
        return hours > 0 ? String(format: "%d:%02d:%02d", hours, minutes, secs)
            : String(format: "%d:%02d", minutes, secs)
    }

    /// Where a scrub ends: a drag across `width` points covers the whole video. Stays in 0…duration.
    static func scrubbed(from start: TimeInterval, by translation: Double, width: Double,
                         duration: TimeInterval) -> TimeInterval {
        guard duration > 0, width > 0 else { return 0 }
        return min(max(start + translation / width * duration, 0), duration)
    }
}
