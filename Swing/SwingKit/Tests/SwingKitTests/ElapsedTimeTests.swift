import Foundation
import Testing
import SwingKit

struct ElapsedTimeTests {
    let nineAM = Date(timeIntervalSinceReferenceDate: 9 * 3600)
    let minute: TimeInterval = 60
    let hour: TimeInterval = 3600

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

    @Test func breaksAreSubtracted() {
        let end = nineAM + 3 * hour
        let breaks = [
            SessionBreak(start: nineAM + hour, end: nineAM + hour + 15 * minute),
            SessionBreak(start: nineAM + 2 * hour, end: nineAM + 2 * hour + 30 * minute),
        ]
        #expect(elapsedTime(start: nineAM, end: end, breaks: breaks) == 3 * hour - 45 * minute)
    }

    @Test func breakWithNoEndLastsUntilNow() {
        let breaks = [SessionBreak(start: nineAM + hour)]
        let now = nineAM + 2 * hour
        #expect(elapsedTime(start: nineAM, end: nil, breaks: breaks, now: now) == hour)
    }

    @Test func overlappingBreaksCountOnce() {
        let breaks = [
            SessionBreak(start: nineAM + 10 * minute, end: nineAM + 30 * minute),
            SessionBreak(start: nineAM + 20 * minute, end: nineAM + 40 * minute),
        ]
        #expect(elapsedTime(start: nineAM, end: nineAM + hour, breaks: breaks) == 30 * minute)
    }

    @Test func breaksOutsideTheSessionOnlyCountTheirInsidePart() {
        let breaks = [
            SessionBreak(start: nineAM - hour, end: nineAM + 10 * minute),
            SessionBreak(start: nineAM + 50 * minute, end: nineAM + 2 * hour),
            SessionBreak(start: nineAM + 3 * hour, end: nineAM + 4 * hour),
        ]
        #expect(elapsedTime(start: nineAM, end: nineAM + hour, breaks: breaks) == 40 * minute)
    }

    @Test func breakCoveringTheWholeSessionLeavesZero() {
        let breaks = [SessionBreak(start: nineAM, end: nineAM + hour)]
        #expect(elapsedTime(start: nineAM, end: nineAM + hour, breaks: breaks) == 0)
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
