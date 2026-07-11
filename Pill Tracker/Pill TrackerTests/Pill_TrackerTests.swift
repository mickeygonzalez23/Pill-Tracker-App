//
//  Pill_TrackerTests.swift
//  Pill TrackerTests
//
//  Created by Jose Gonzalez on 6/11/26.
//

import Foundation
import Testing
@testable import Pill_Tracker

struct Pill_TrackerTests {
    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 7, day: day, hour: hour, minute: minute))!
    }

    private func intervalMedication(start: Date, finish: Date, hours: Int = 4) -> Medication {
        Medication(realName: "Test", dose: "1 pill", siriNickname: "test pill", doseTime: "8:00 PM",
                   scheduleKind: .everyXHours, intervalHours: hours,
                   intervalStartDate: start, intervalFinishDate: finish, createdAt: start)
    }

    @Test func doseStatusesReplaceAndClear() {
        var medication = intervalMedication(start: date(10, 20), finish: date(10, 23))
        medication.setDoseStatus(.taken, for: "8:00 PM", on: date(10, 20))
        medication.setDoseStatus(.skipped, for: "8:00 PM", on: date(10, 20))
        #expect(medication.doseStatus(for: "8:00 PM", on: date(10, 20)) == .skipped)
        #expect(!medication.takenDoseTimesToday.contains("8:00 PM"))
        medication.setDoseStatus(nil, for: "8:00 PM", on: date(10, 20))
        #expect(medication.doseStatus(for: "8:00 PM", on: date(10, 20)) == .due)
    }

    @Test func intervalContinuesAcrossMidnightAndIncludesAlignedFinish() {
        let medication = intervalMedication(start: date(10, 20), finish: date(11, 8))
        #expect(medication.intervalOccurrences() == [date(10, 20), date(11, 0), date(11, 4), date(11, 8)])
        #expect(medication.doseTimes(on: date(10, 12)) == ["8:00 PM"])
        #expect(medication.doseTimes(on: date(11, 12)) == ["12:00 AM", "4:00 AM", "8:00 AM"])
    }

    @Test func intervalStopsBeforeNonAlignedFinish() {
        let medication = intervalMedication(start: date(10, 20), finish: date(11, 7))
        #expect(medication.intervalOccurrences().last == date(11, 4))
    }

    @Test func legacyIntervalDecodesWithNextDayFinish() throws {
        let original = intervalMedication(start: date(10, 20), finish: date(11, 8))
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
        object.removeValue(forKey: "intervalStartDate")
        object.removeValue(forKey: "intervalFinishDate")
        object["intervalStartTime"] = "8:00 PM"
        object["intervalEndTime"] = "8:00 AM"
        let decoded = try JSONDecoder().decode(Medication.self, from: JSONSerialization.data(withJSONObject: object))
        #expect(decoded.intervalStartDate != nil)
        #expect(decoded.intervalFinishDate != nil)
        #expect(decoded.intervalFinishDate! > decoded.intervalStartDate!)
    }

    @Test @MainActor func dailyNotesSaveUpdateDeleteAndReload() throws {
        let suite = "PillTrackerTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let day = date(10, 12)
        let store = MedicationStore(defaults: defaults, scheduleNotifications: false)
        store.updateNote(" First note ", for: day)
        #expect(store.note(for: day) == "First note")
        store.updateNote("Updated", for: day)
        let reloaded = MedicationStore(defaults: defaults, scheduleNotifications: false)
        #expect(reloaded.note(for: day) == "Updated")
        reloaded.updateNote("   ", for: day)
        #expect(reloaded.note(for: day).isEmpty)
    }
}
