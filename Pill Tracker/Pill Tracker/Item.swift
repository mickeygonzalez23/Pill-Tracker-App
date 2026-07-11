//
//  Item.swift
//  Pill Tracker
//
//  Created by Jose Gonzalez on 6/11/26.
//

import AppIntents
import Combine
import Foundation

struct DoseStatusLogEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var status: String
    var changedAt: Date
}

struct Medication: Identifiable, Codable, Equatable {
    var id = UUID()
    var realName: String
    var dose: String
    var siriNickname: String
    var doseTime: String
    var scheduleKind: ScheduleKind = .onceDaily
    var doseTimes: [String] = []
    var intervalHours: Int = 4
    var intervalStartTime: String = "8:00 AM"
    var intervalEndTime: String = "8:00 PM"
    var intervalStartDate: Date?
    var intervalFinishDate: Date?
    var dayScheduleKind: DayScheduleKind = .everyDay
    var selectedWeekdays: [Int] = Weekday.allCases.map(\.id)
    var takenDoseTimesToday: [String] = []
    var unsureDoseTimesToday: [String] = []
    var doseStatusHistory: [String: [String: String]] = [:]
    var doseStatusUpdatedAtHistory: [String: [String: Date]] = [:]
    var doseStatusLogHistory: [String: [String: [DoseStatusLogEntry]]] = [:]
    var remindersEnabled = true
    var createdAt = Date()

    nonisolated var displayDoseTimes: [String] {
        if !doseTimes.isEmpty {
            return doseTimes
        }

        return [doseTime]
    }

    var scheduleSummary: String {
        switch scheduleKind {
        case .onceDaily:
            return displayDoseTimes.first ?? doseTime
        case .twiceDaily, .specificTimes:
            return displayDoseTimes.joined(separator: ", ")
        case .everyXHours:
            guard let start = intervalStartDate, let finish = intervalFinishDate else {
                return "Every \(intervalHours) hours, \(intervalStartTime)-\(intervalEndTime)"
            }
            return "Every \(intervalHours) hours, \(Self.rangeFormatter.string(from: start))-\(Self.rangeFormatter.string(from: finish))"
        }
    }

    nonisolated static let rangeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    var isTakenToday: Bool {
        get {
            !displayDoseTimes.isEmpty && displayDoseTimes.allSatisfy { takenDoseTimesToday.contains($0) }
        }
        set {
            takenDoseTimesToday = newValue ? displayDoseTimes : []
        }
    }

    var daySummary: String {
        switch dayScheduleKind {
        case .everyDay:
            return "Every day"
        case .specificDays:
            return Weekday.allCases
                .filter { selectedWeekdays.contains($0.id) }
                .map(\.shortName)
                .joined(separator: ", ")
        }
    }

    var isDueToday: Bool {
        dayScheduleKind == .everyDay || selectedWeekdays.contains(Weekday.todayID)
    }

    init(
        id: UUID = UUID(),
        realName: String,
        dose: String,
        siriNickname: String,
        doseTime: String,
        scheduleKind: ScheduleKind = .onceDaily,
        doseTimes: [String] = [],
        intervalHours: Int = 4,
        intervalStartTime: String = "8:00 AM",
        intervalEndTime: String = "8:00 PM",
        intervalStartDate: Date? = nil,
        intervalFinishDate: Date? = nil,
        dayScheduleKind: DayScheduleKind = .everyDay,
        selectedWeekdays: [Int] = Weekday.allCases.map(\.id),
        takenDoseTimesToday: [String] = [],
        unsureDoseTimesToday: [String] = [],
        doseStatusHistory: [String: [String: String]] = [:],
        doseStatusUpdatedAtHistory: [String: [String: Date]] = [:],
        doseStatusLogHistory: [String: [String: [DoseStatusLogEntry]]] = [:],
        remindersEnabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.realName = realName
        self.dose = dose
        self.siriNickname = siriNickname
        self.doseTime = doseTime
        self.scheduleKind = scheduleKind
        self.doseTimes = doseTimes.isEmpty ? [doseTime] : doseTimes
        self.intervalHours = intervalHours
        self.intervalStartTime = intervalStartTime
        self.intervalEndTime = intervalEndTime
        self.intervalStartDate = intervalStartDate
        self.intervalFinishDate = intervalFinishDate
        self.dayScheduleKind = dayScheduleKind
        self.selectedWeekdays = selectedWeekdays
        self.takenDoseTimesToday = takenDoseTimesToday
        self.unsureDoseTimesToday = unsureDoseTimesToday
        self.doseStatusHistory = doseStatusHistory
        self.doseStatusUpdatedAtHistory = doseStatusUpdatedAtHistory
        self.doseStatusLogHistory = doseStatusLogHistory
        self.remindersEnabled = remindersEnabled
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case realName
        case dose
        case siriNickname
        case doseTime
        case scheduleKind
        case doseTimes
        case intervalHours
        case intervalStartTime
        case intervalEndTime
        case intervalStartDate
        case intervalFinishDate
        case dayScheduleKind
        case selectedWeekdays
        case takenDoseTimesToday
        case unsureDoseTimesToday
        case doseStatusHistory
        case doseStatusUpdatedAtHistory
        case doseStatusLogHistory
        case remindersEnabled
        case isTakenToday
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        realName = try container.decode(String.self, forKey: .realName)
        dose = try container.decode(String.self, forKey: .dose)
        siriNickname = try container.decode(String.self, forKey: .siriNickname)
        doseTime = try container.decode(String.self, forKey: .doseTime)
        scheduleKind = try container.decodeIfPresent(ScheduleKind.self, forKey: .scheduleKind) ?? .onceDaily
        doseTimes = try container.decodeIfPresent([String].self, forKey: .doseTimes) ?? [doseTime]
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        intervalHours = try container.decodeIfPresent(Int.self, forKey: .intervalHours) ?? 4
        intervalStartTime = try container.decodeIfPresent(String.self, forKey: .intervalStartTime) ?? "8:00 AM"
        intervalEndTime = try container.decodeIfPresent(String.self, forKey: .intervalEndTime) ?? "8:00 PM"
        intervalStartDate = try container.decodeIfPresent(Date.self, forKey: .intervalStartDate)
        intervalFinishDate = try container.decodeIfPresent(Date.self, forKey: .intervalFinishDate)
        if scheduleKind == .everyXHours && (intervalStartDate == nil || intervalFinishDate == nil) {
            intervalStartDate = Self.legacyDate(time: intervalStartTime, anchoredTo: createdAt)
            intervalFinishDate = Self.legacyDate(time: intervalEndTime, anchoredTo: createdAt)
            if let start = intervalStartDate, let finish = intervalFinishDate, finish < start {
                intervalFinishDate = Calendar.current.date(byAdding: .day, value: 1, to: finish)
            }
        }
        dayScheduleKind = try container.decodeIfPresent(DayScheduleKind.self, forKey: .dayScheduleKind) ?? .everyDay
        selectedWeekdays = try container.decodeIfPresent([Int].self, forKey: .selectedWeekdays) ?? Weekday.allCases.map(\.id)
        takenDoseTimesToday = try container.decodeIfPresent([String].self, forKey: .takenDoseTimesToday) ?? []
        unsureDoseTimesToday = try container.decodeIfPresent([String].self, forKey: .unsureDoseTimesToday) ?? []
        doseStatusHistory = try container.decodeIfPresent([String: [String: String]].self, forKey: .doseStatusHistory) ?? [:]
        doseStatusUpdatedAtHistory = try container.decodeIfPresent([String: [String: Date]].self, forKey: .doseStatusUpdatedAtHistory) ?? [:]
        doseStatusLogHistory = try container.decodeIfPresent([String: [String: [DoseStatusLogEntry]]].self, forKey: .doseStatusLogHistory) ?? [:]
        remindersEnabled = try container.decodeIfPresent(Bool.self, forKey: .remindersEnabled) ?? true

        if try container.decodeIfPresent(Bool.self, forKey: .isTakenToday) == true {
            takenDoseTimesToday = doseTimes
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(realName, forKey: .realName)
        try container.encode(dose, forKey: .dose)
        try container.encode(siriNickname, forKey: .siriNickname)
        try container.encode(doseTime, forKey: .doseTime)
        try container.encode(scheduleKind, forKey: .scheduleKind)
        try container.encode(doseTimes, forKey: .doseTimes)
        try container.encode(intervalHours, forKey: .intervalHours)
        try container.encode(intervalStartTime, forKey: .intervalStartTime)
        try container.encode(intervalEndTime, forKey: .intervalEndTime)
        try container.encodeIfPresent(intervalStartDate, forKey: .intervalStartDate)
        try container.encodeIfPresent(intervalFinishDate, forKey: .intervalFinishDate)
        try container.encode(dayScheduleKind, forKey: .dayScheduleKind)
        try container.encode(selectedWeekdays, forKey: .selectedWeekdays)
        try container.encode(takenDoseTimesToday, forKey: .takenDoseTimesToday)
        try container.encode(unsureDoseTimesToday, forKey: .unsureDoseTimesToday)
        try container.encode(doseStatusHistory, forKey: .doseStatusHistory)
        try container.encode(doseStatusUpdatedAtHistory, forKey: .doseStatusUpdatedAtHistory)
        try container.encode(doseStatusLogHistory, forKey: .doseStatusLogHistory)
        try container.encode(remindersEnabled, forKey: .remindersEnabled)
        try container.encode(createdAt, forKey: .createdAt)
    }

    private nonisolated static func legacyDate(time: String, anchoredTo date: Date) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        guard let parsed = formatter.date(from: time) else { return nil }
        let calendar = Calendar.current
        let timeParts = calendar.dateComponents([.hour, .minute], from: parsed)
        return calendar.date(bySettingHour: timeParts.hour ?? 0, minute: timeParts.minute ?? 0, second: 0, of: date)
    }
}

enum ScheduleKind: String, CaseIterable, Codable, Identifiable {
    case onceDaily = "Once daily"
    case twiceDaily = "Twice daily"
    case specificTimes = "Specific times"
    case everyXHours = "Every X hours"

    var id: String {
        rawValue
    }
}

enum DayScheduleKind: String, CaseIterable, Codable, Identifiable {
    case everyDay = "Every day"
    case specificDays = "Specific days"

    var id: String {
        rawValue
    }
}

enum Weekday: Int, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var id: Int {
        rawValue
    }

    var shortName: String {
        switch self {
        case .sunday:
            return "Sun"
        case .monday:
            return "Mon"
        case .tuesday:
            return "Tue"
        case .wednesday:
            return "Wed"
        case .thursday:
            return "Thu"
        case .friday:
            return "Fri"
        case .saturday:
            return "Sat"
        }
    }

    static var todayID: Int {
        Calendar.current.component(.weekday, from: Date())
    }
}

final class MedicationStore: ObservableObject {
    @Published var medications: [Medication] = [] {
        didSet {
            save()
            NotificationScheduler.scheduleReminders(for: medications)
        }
    }
    @Published private(set) var dailyNotes: [String: String] = [:] {
        didSet { saveNotes() }
    }

    private let storageKey = "savedMedications"
    private let notesStorageKey = "dailyNotes"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard, scheduleNotifications: Bool = true) {
        self.defaults = defaults
        load()
        loadNotes()
        if scheduleNotifications {
            NotificationScheduler.requestPermissionAndSchedule(for: medications)
        }
    }

    func add(_ medication: Medication) {
        medications.append(medication)
    }

    func update(_ medication: Medication) {
        guard let index = medications.firstIndex(where: { $0.id == medication.id }) else {
            return
        }

        medications[index] = medication
    }

    func delete(_ medication: Medication) {
        medications.removeAll { $0.id == medication.id }
    }

    func reload() {
        load()
        loadNotes()
    }

    func resetAllData() {
        medications = []
        dailyNotes = [:]
        defaults.removeObject(forKey: storageKey)
        defaults.removeObject(forKey: notesStorageKey)
        NotificationScheduler.cancelMedicationReminders()
    }

    func note(for date: Date) -> String {
        dailyNotes[Self.dateKey(for: date)] ?? ""
    }

    func updateNote(_ note: String, for date: Date) {
        let key = Self.dateKey(for: date)
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        dailyNotes[key] = trimmed.isEmpty ? nil : trimmed
    }

    private func load() {
        guard
            let data = defaults.data(forKey: storageKey),
            let savedMedications = try? JSONDecoder().decode([Medication].self, from: data)
        else {
            return
        }

        medications = savedMedications
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(medications) else {
            return
        }

        defaults.set(data, forKey: storageKey)
        PillTrackerShortcuts.updateAppShortcutParameters()
    }

    private func loadNotes() {
        dailyNotes = defaults.dictionary(forKey: notesStorageKey) as? [String: String] ?? [:]
    }

    private func saveNotes() {
        defaults.set(dailyNotes, forKey: notesStorageKey)
    }

    private static func dateKey(for date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}
