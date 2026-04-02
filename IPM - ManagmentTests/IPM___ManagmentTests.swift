import XCTest
@testable import IPM___Managment

final class IPMManagementTests: XCTestCase {
    func testNextInspectionDateUsesLatestRemainingInspection() {
        let calendar = Calendar(identifier: .gregorian)
        let fallbackDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let olderInspection = Inspection(
            datum: calendar.date(from: DateComponents(year: 2025, month: 1, day: 3))!,
            temperatur: nil,
            luftfeuchtigkeit: nil,
            notizen: ""
        )
        let latestInspection = Inspection(
            datum: calendar.date(from: DateComponents(year: 2025, month: 1, day: 10))!,
            temperatur: nil,
            luftfeuchtigkeit: nil,
            notizen: ""
        )

        let result = FirestoreService.nextInspectionDate(
            from: [olderInspection, latestInspection],
            fallbackDate: fallbackDate,
            intervalDays: 14
        )

        XCTAssertEqual(
            result,
            calendar.date(from: DateComponents(year: 2025, month: 1, day: 24))
        )
    }

    func testNextInspectionDateFallsBackToInstallDateWhenNoInspectionRemains() {
        let calendar = Calendar(identifier: .gregorian)
        let fallbackDate = calendar.date(from: DateComponents(year: 2025, month: 2, day: 5))!

        let result = FirestoreService.nextInspectionDate(
            from: [],
            fallbackDate: fallbackDate,
            intervalDays: 28
        )

        XCTAssertEqual(
            result,
            calendar.date(from: DateComponents(year: 2025, month: 3, day: 5))
        )
    }

    func testTrapInspectionIntervalRoundsToWholeWeeks() {
        let trap = Trap(nummer: "A-12", typ: .gTrap, pruefIntervallTage: 56)
        XCTAssertEqual(trap.pruefIntervallWochen, 8)
    }
}
