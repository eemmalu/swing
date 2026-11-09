import Foundation

// The part of a session that falls on one calendar day
public struct DayPart: Equatable {
    public let day: Date
    public let start: Date
    public let end: Date

    public init(day: Date, start: Date, end: Date) {
        self.day = day
        self.start = start
        self.end = end
    }

    public var duration: TimeInterval { end.timeIntervalSince(start) }
}

/// Takes in a session's start and end time, its list of breaks, and the current time. 
/// Parses the session into working spans and splits them into day parts if they span multiple days.
/// Returns a list of `DayPart` structs representing the parts of the session that fall on each calendar day.
public func dayParts(
    start: Date, end: Date?, breaks: [SessionBreak] = [], now: Date = .now, calendar: Calendar = .current
) -> [DayPart] {
    var parts: [DayPart] = []
    for span in workedSpans(start: start, end: end, breaks: breaks, now: now) {
        var partStart = span.start
        while partStart < span.end, let day = calendar.dateInterval(of: .day, for: partStart) {
            let partEnd = min(day.end, span.end)
            parts.append(DayPart(day: day.start, start: partStart, end: partEnd))
            partStart = partEnd
        }
    }
    return parts
}
