import Foundation

/// Seconds from `start` to `end`, or to `now` while running. Does not include breaks.
public func elapsedTime(start: Date, end: Date?, breaks: [SessionBreak] = [], now: Date = .now) -> TimeInterval {
    workedSpans(start: start, end: end, breaks: breaks, now: now)
        .map { $0.end.timeIntervalSince($0.start) }
        .reduce(0, +)
}

/// Takes in the start and end time of a session and its list of breaks. Returns a list of the time spans
/// spent working. If there is a break with no end, the break is considered to last until `now`.
func workedSpans(start: Date, end: Date?, breaks: [SessionBreak], now: Date) -> [(start: Date, end: Date)] {
    let end = end ?? now
    let gaps = breaks
        .map { (start: max($0.start, start), end: min($0.end ?? now, end)) }
        .filter { $0.start < $0.end }
        .sorted { $0.start < $1.start }
    var spans: [(start: Date, end: Date)] = []
    var spanStart = start
    for gap in gaps {
        if spanStart < gap.start {
            spans.append((spanStart, gap.start))
        }
        spanStart = max(spanStart, gap.end)
    }
    if spanStart < end {
        spans.append((spanStart, end))
    }
    return spans
}

/// Elapsed time formatted as a string
public func formattedElapsedTime(_ seconds: TimeInterval, locale: Locale = .autoupdatingCurrent) -> String {
    Duration.seconds(Int(max(0, seconds)))
        .formatted(.time(pattern: .hourMinuteSecond).locale(locale))
}
