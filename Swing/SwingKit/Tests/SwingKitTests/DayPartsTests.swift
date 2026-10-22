import Foundation
import Testing
import SwingKit

struct DayPartsTests {
    let calendar = Self.calendar(timeZone: "Europe/London")
    let hour: TimeInterval = 3600

    static func calendar(timeZone: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZone)!
        return calendar
    }

    func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    @Test func sessionWithinOneDayIsOnePart() {
        let parts = dayParts(start: date(2026, 5, 4, 9), end: date(2026, 5, 4, 10, 30), calendar: calendar)
        #expect(parts == [DayPart(day: date(2026, 5, 4), start: date(2026, 5, 4, 9), end: date(2026, 5, 4, 10, 30))])
    }

    @Test func sessionCrossingMidnightIsSplit() {
        let parts = dayParts(start: date(2026, 5, 4, 23), end: date(2026, 5, 5, 1), calendar: calendar)
        #expect(parts == [
            DayPart(day: date(2026, 5, 4), start: date(2026, 5, 4, 23), end: date(2026, 5, 5)),
            DayPart(day: date(2026, 5, 5), start: date(2026, 5, 5), end: date(2026, 5, 5, 1)),
        ])
    }

    @Test func sessionOverSeveralDaysHasAPartForEachDay() {
        let parts = dayParts(start: date(2026, 5, 4, 22), end: date(2026, 5, 6, 2), calendar: calendar)
        #expect(parts.map(\.day) == [date(2026, 5, 4), date(2026, 5, 5), date(2026, 5, 6)])
        #expect(parts.map(\.duration) == [2 * hour, 24 * hour, 2 * hour])
    }

    @Test func runningSessionIsSplitUpToNow() {
        let parts = dayParts(start: date(2026, 5, 4, 23), end: nil, now: date(2026, 5, 5, 0, 30), calendar: calendar)
        #expect(parts.map(\.duration) == [hour, hour / 2])
    }

    @Test func sessionEndingAtMidnightIsOnePart() {
        let parts = dayParts(start: date(2026, 5, 4, 22), end: date(2026, 5, 5), calendar: calendar)
        #expect(parts.map(\.day) == [date(2026, 5, 4)])
    }

    @Test func sessionStartingAtMidnightIsOnePart() {
        let parts = dayParts(start: date(2026, 5, 5), end: date(2026, 5, 5, 1), calendar: calendar)
        #expect(parts.map(\.day) == [date(2026, 5, 5)])
    }

    @Test func sessionEndingBeforeItStartsHasNoParts() {
        #expect(dayParts(start: date(2026, 5, 4, 10), end: date(2026, 5, 4, 9), calendar: calendar).isEmpty)
        #expect(dayParts(start: date(2026, 5, 4, 10), end: date(2026, 5, 4, 10), calendar: calendar).isEmpty)
    }

    @Test func dayWhenClocksGoForwardIs23Hours() {
        let parts = dayParts(start: date(2026, 3, 28, 22), end: date(2026, 3, 30, 2), calendar: calendar)
        #expect(parts.map(\.day) == [date(2026, 3, 28), date(2026, 3, 29), date(2026, 3, 30)])
        #expect(parts.map(\.duration) == [2 * hour, 23 * hour, 2 * hour])
    }

    @Test func dayWhenClocksGoBackIs25Hours() {
        let parts = dayParts(start: date(2026, 10, 24, 22), end: date(2026, 10, 26, 2), calendar: calendar)
        #expect(parts.map(\.day) == [date(2026, 10, 24), date(2026, 10, 25), date(2026, 10, 26)])
        #expect(parts.map(\.duration) == [2 * hour, 25 * hour, 2 * hour])
    }

    // In Santiago, clocks go from midnight straight to 1:00 when summer time starts
    @Test func dayStartingAtOneInTheMorningIsSplitThere() {
        let santiago = Self.calendar(timeZone: "America/Santiago")
        let start = santiago.date(from: DateComponents(year: 2026, month: 9, day: 5, hour: 22))!
        let end = santiago.date(from: DateComponents(year: 2026, month: 9, day: 6, hour: 3))!
        let parts = dayParts(start: start, end: end, calendar: santiago)

        #expect(parts.map(\.duration) == [2 * hour, 2 * hour])
        #expect(santiago.component(.hour, from: parts[1].start) == 1)
    }

    @Test func partsAddUpToElapsedTime() {
        let start = date(2026, 10, 24, 21, 15)
        let end = date(2026, 10, 27, 8, 40)
        let total = dayParts(start: start, end: end, calendar: calendar).map(\.duration).reduce(0, +)
        #expect(total == elapsedTime(start: start, end: end))
    }
}
