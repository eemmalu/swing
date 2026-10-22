import Foundation

// The part of a session that falls on one calendar day
public struct DayPart: Equatable {
    // Start of the day this part falls on
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

// Splits the time from `start` to `end`, or to `now` while running, at each local midnight. Empty when it ends before it starts
public func dayParts(start: Date, end: Date?, now: Date = .now, calendar: Calendar = .current) -> [DayPart] {
    let end = end ?? now
    var parts: [DayPart] = []
    var partStart = start
    while partStart < end, let day = calendar.dateInterval(of: .day, for: partStart) {
        let partEnd = min(day.end, end)
        parts.append(DayPart(day: day.start, start: partStart, end: partEnd))
        partStart = partEnd
    }
    return parts
}
