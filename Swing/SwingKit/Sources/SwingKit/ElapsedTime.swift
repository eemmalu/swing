import Foundation

/// Seconds from `start` to `end`, or to `now` while running. Never negative.
public func elapsedTime(start: Date, end: Date?, now: Date = .now) -> TimeInterval {
    max(0, (end ?? now).timeIntervalSince(start))
}

/// Elapsed time as the timer shows it, such as "1:02:05". Partial seconds are dropped.
public func formattedElapsedTime(_ seconds: TimeInterval, locale: Locale = .autoupdatingCurrent) -> String {
    Duration.seconds(Int(max(0, seconds)))
        .formatted(.time(pattern: .hourMinuteSecond).locale(locale))
}
