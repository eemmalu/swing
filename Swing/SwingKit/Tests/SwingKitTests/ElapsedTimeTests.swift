import Foundation
import Testing
import SwingKit

struct ElapsedTimeTests {
    let nineAM = Date(timeIntervalSinceReferenceDate: 9 * 3600)

    @Test func finishedSessionUsesItsEnd() {
        let end = nineAM.addingTimeInterval(90 * 60)
        let later = end.addingTimeInterval(3600)
        #expect(elapsedTime(start: nineAM, end: end, now: later) == 90 * 60)
    }

    @Test func runningSessionUsesNow() {
        let now = nineAM.addingTimeInterval(25 * 60)
        #expect(elapsedTime(start: nineAM, end: nil, now: now) == 25 * 60)
    }

    @Test func sessionCrossingMidnightIsOneLength() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/New_York"))
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 24, hour: 23, minute: 30)))
        let end = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 25, hour: 0, minute: 45)))
        #expect(elapsedTime(start: start, end: end) == 75 * 60)
    }

    @Test func endBeforeStartIsZero() {
        let end = nineAM.addingTimeInterval(-60)
        #expect(elapsedTime(start: nineAM, end: end) == 0)
    }
}

struct FormattedElapsedTimeTests {
    let english = Locale(identifier: "en_US")

    @Test func notStartedShowsZero() {
        #expect(formattedElapsedTime(0, locale: english) == "0:00:00")
    }

    @Test func partialSecondsAreDropped() {
        #expect(formattedElapsedTime(59.9, locale: english) == "0:00:59")
    }

    @Test func showsHoursMinutesAndSeconds() {
        #expect(formattedElapsedTime(3725, locale: english) == "1:02:05")
        #expect(formattedElapsedTime(10 * 3600, locale: english) == "10:00:00")
    }
}
