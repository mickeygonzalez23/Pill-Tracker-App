//
//  PillTrackerIntents.swift
//  Pill Tracker
//
//  Created by Jose Gonzalez on 6/11/26.
//

import AppIntents
import Foundation

struct MedicationEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Medication")
    static var defaultQuery = MedicationEntityQuery()

    let id: String
    let name: String
    let realName: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct MedicationEntityQuery: EntityStringQuery {
    func entities(for identifiers: [MedicationEntity.ID]) async throws -> [MedicationEntity] {
        MedicationIntentStore.medicationEntities().filter { identifiers.contains($0.id) }
    }

    func entities(matching string: String) async throws -> [MedicationEntity] {
        let searchText = normalized(string)

        guard !searchText.isEmpty else {
            return MedicationIntentStore.medicationEntities()
        }

        return MedicationIntentStore.medicationEntities().filter { entity in
            let name = normalized(entity.name)
            return name == searchText ||
                name.contains(searchText) ||
                searchText.contains(name)
        }
    }

    func suggestedEntities() async throws -> [MedicationEntity] {
        MedicationIntentStore.medicationEntities()
    }

    func defaultResult() async -> MedicationEntity? {
        nil
    }

    private func normalized(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

struct DoseTimeEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Dose Time")
    static var defaultQuery = DoseTimeEntityQuery()

    let id: String
    let time: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(time)")
    }
}

struct DoseTimeEntityQuery: EntityStringQuery {
    func entities(for identifiers: [DoseTimeEntity.ID]) async throws -> [DoseTimeEntity] {
        identifiers.map { DoseTimeEntity(id: $0, time: $0) }
    }

    func entities(matching string: String) async throws -> [DoseTimeEntity] {
        doseTimeOptions
            .filter { normalized($0).contains(normalized(string)) }
            .map { DoseTimeEntity(id: $0, time: $0) }
    }

    func suggestedEntities() async throws -> [DoseTimeEntity] {
        doseTimeOptions.map { DoseTimeEntity(id: $0, time: $0) }
    }

    private var doseTimeOptions: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        return stride(from: 0, to: 24 * 60, by: 5).compactMap { minuteOffset in
            guard let date = calendar.date(byAdding: .minute, value: minuteOffset, to: startOfDay) else {
                return nil
            }

            return formatter.string(from: date)
        }
    }

    private func normalized(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

enum DoseNumber: String, AppEnum {
    case first
    case second
    case third
    case fourth
    case fifth
    case sixth

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Dose Number")
    static var caseDisplayRepresentations: [DoseNumber: DisplayRepresentation] = [
        .first: "first",
        .second: "second",
        .third: "third",
        .fourth: "fourth",
        .fifth: "fifth",
        .sixth: "sixth"
    ]

    var index: Int {
        switch self {
        case .first:
            return 0
        case .second:
            return 1
        case .third:
            return 2
        case .fourth:
            return 3
        case .fifth:
            return 4
        case .sixth:
            return 5
        }
    }
}

struct MarkMedicationTakenIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Medication Taken"
    static var description = IntentDescription("Marks the next relevant dose for a medication as taken using its private Siri name.")
    static var openAppWhenRun = false

    @Parameter(title: "Medication")
    var medication: MedicationEntity

    @Parameter(title: "Dose Time")
    var doseTime: DoseTimeEntity?

    init() {
        medication = MedicationEntity(id: "", name: "", realName: "")
        doseTime = nil
    }

    init(medication: MedicationEntity) {
        self.medication = medication
        doseTime = nil
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = try await markDose(as: .taken)
        return .result(dialog: IntentDialog(stringLiteral: message))
    }

    private func markDose(as status: DoseStatus) async throws -> String {
        let selection = MedicationIntentStore.doseSelection(for: medication.id, selectedDoseTime: doseTime?.time)

        if let message = selection.message {
            return message
        }

        if selection.needsChoice {
            let options = selection.candidateDoseTimes.map { DoseTimeEntity(id: $0, time: $0) }
            let selectedDoseTime = try await $doseTime.requestDisambiguation(
                among: options,
                dialog: "Which dose time?"
            )
            return MedicationIntentStore.markMedicationDoseWithMessage(
                id: medication.id,
                doseTime: selectedDoseTime.time,
                as: status
            )
        }

        guard let doseTime = selection.doseTime else {
            return "I could not find a dose to log."
        }

        return MedicationIntentStore.markMedicationDoseWithMessage(id: medication.id, doseTime: doseTime, as: status)
    }
}

struct MarkMedicationUnsureIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Medication Not Sure"
    static var description = IntentDescription("Marks the next relevant dose for a medication as not sure using its private Siri name.")
    static var openAppWhenRun = false

    @Parameter(title: "Medication")
    var medication: MedicationEntity

    @Parameter(title: "Dose Time")
    var doseTime: DoseTimeEntity?

    init() {
        medication = MedicationEntity(id: "", name: "", realName: "")
        doseTime = nil
    }

    init(medication: MedicationEntity) {
        self.medication = medication
        doseTime = nil
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = try await markDose(as: .unsure)
        return .result(dialog: IntentDialog(stringLiteral: message))
    }

    private func markDose(as status: DoseStatus) async throws -> String {
        let selection = MedicationIntentStore.doseSelection(for: medication.id, selectedDoseTime: doseTime?.time)

        if let message = selection.message {
            return message
        }

        if selection.needsChoice {
            let options = selection.candidateDoseTimes.map { DoseTimeEntity(id: $0, time: $0) }
            let selectedDoseTime = try await $doseTime.requestDisambiguation(
                among: options,
                dialog: "Which dose time?"
            )
            return MedicationIntentStore.markMedicationDoseWithMessage(
                id: medication.id,
                doseTime: selectedDoseTime.time,
                as: status
            )
        }

        guard let doseTime = selection.doseTime else {
            return "I could not find a dose to log."
        }

        return MedicationIntentStore.markMedicationDoseWithMessage(id: medication.id, doseTime: doseTime, as: status)
    }
}

struct CheckDueMedicationsIntent: AppIntent {
    static var title: LocalizedStringResource = "Pill Tracker Status"
    static var description = IntentDescription("Gives a status report for medications still due today.")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = MedicationIntentStore.dueMedicationsSummary()
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

struct PillTrackerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: MarkMedicationTakenIntent(),
            phrases: [
                "Mark \(\.$medication) as taken in \(.applicationName)",
                "I took \(\.$medication) in \(.applicationName)"
            ],
            shortTitle: "Mark Taken",
            systemImageName: "checkmark.circle"
        )

        AppShortcut(
            intent: MarkMedicationUnsureIntent(),
            phrases: [
                "Mark \(\.$medication) as not sure in \(.applicationName)",
                "I'm not sure if I took \(\.$medication) in \(.applicationName)"
            ],
            shortTitle: "Not Sure",
            systemImageName: "questionmark.circle"
        )

        AppShortcut(
            intent: CheckDueMedicationsIntent(),
            phrases: [
                "\(.applicationName) status report",
                "\(.applicationName) medication status",
                "\(.applicationName) pill status",
                "Run status report in \(.applicationName)",
                "Did I take my pills in \(.applicationName)",
                "Check my pills in \(.applicationName)",
                "Check pill status in \(.applicationName)",
                "What's due in \(.applicationName)",
                "What meds are due in \(.applicationName)",
                "List due meds in \(.applicationName)"
            ],
            shortTitle: "What's Due",
            systemImageName: "clock"
        )
    }
}

enum MedicationIntentStore {
    nonisolated private static let storageKey = "savedMedications"

    struct DoseSelection {
        var doseTime: String?
        var candidateDoseTimes: [String]
        var needsChoice: Bool
        var message: String?
    }

    nonisolated static func medicationEntities() -> [MedicationEntity] {
        loadMedications().map {
            MedicationEntity(id: $0.id.uuidString, name: $0.siriNickname, realName: $0.realName)
        }
    }

    nonisolated static func medication(id medicationID: String) -> Medication? {
        loadMedications().first { $0.id.uuidString == medicationID }
    }

    nonisolated static func markMedication(id medicationID: String, as status: DoseStatus) -> String {
        var medications = loadMedications()

        guard let index = medications.firstIndex(where: {
            $0.id.uuidString == medicationID
        }) else {
            return "I could not find that medication."
        }

        guard medications[index].isScheduled(on: Date()) else {
            return "\(medications[index].siriNickname) is not scheduled for today."
        }

        let doseTimes = medications[index].displayDoseTimes
        for doseTime in doseTimes {
            apply(status, to: &medications[index], doseTime: doseTime)
        }
        saveMedications(medications)

        if status == .taken {
            return "Marked \(medications[index].siriNickname) as taken for today."
        }

        return "Marked \(medications[index].siriNickname) as not sure for today."
    }

    nonisolated static func markNextMedicationDose(id medicationID: String, as status: DoseStatus) -> String {
        let selection = doseSelection(for: medicationID, selectedDoseTime: nil)

        if let message = selection.message {
            return message
        }

        guard let doseTime = selection.doseTime, !selection.needsChoice else {
            return "Please choose which dose time to log."
        }

        return markMedicationDoseWithMessage(id: medicationID, doseTime: doseTime, as: status)
    }

    nonisolated static func doseSelection(for medicationID: String, selectedDoseTime: String?) -> DoseSelection {
        let medications = loadMedications()

        guard let index = medications.firstIndex(where: { $0.id.uuidString == medicationID }) else {
            return DoseSelection(doseTime: nil, candidateDoseTimes: [], needsChoice: false, message: "I could not find that medication.")
        }

        guard medications[index].isScheduled(on: Date()) else {
            return DoseSelection(doseTime: nil, candidateDoseTimes: [], needsChoice: false, message: "\(medications[index].siriNickname) is not scheduled for today.")
        }

        let unloggedDoseTimes = medications[index].displayDoseTimes.filter {
            medications[index].doseStatus(for: $0, on: Date()) == .due
        }

        if let selectedDoseTime {
            guard medications[index].displayDoseTimes.contains(selectedDoseTime) else {
                return DoseSelection(doseTime: nil, candidateDoseTimes: [], needsChoice: false, message: "\(medications[index].siriNickname) does not have a dose scheduled at \(selectedDoseTime).")
            }

            guard unloggedDoseTimes.contains(selectedDoseTime) else {
                return DoseSelection(doseTime: nil, candidateDoseTimes: [], needsChoice: false, message: "\(medications[index].siriNickname) at \(selectedDoseTime) is already logged today.")
            }

            return DoseSelection(doseTime: selectedDoseTime, candidateDoseTimes: [selectedDoseTime], needsChoice: false, message: nil)
        }

        let doseSelection = doseTimeToLog(from: unloggedDoseTimes)

        if let message = doseSelection.message {
            return DoseSelection(
                doseTime: nil,
                candidateDoseTimes: doseSelection.candidateDoseTimes,
                needsChoice: doseSelection.needsChoice,
                message: message.replacingOccurrences(of: "{medication}", with: medications[index].siriNickname)
            )
        }

        return doseSelection
    }

    nonisolated static func markMedicationDose(id medicationID: String, doseTime: String, as status: DoseStatus) {
        _ = markMedicationDoseWithMessage(id: medicationID, doseTime: doseTime, as: status)
    }

    nonisolated static func markMedicationDoseWithMessage(id medicationID: String, doseTime: String, as status: DoseStatus) -> String {
        var medications = loadMedications()

        guard let index = medications.firstIndex(where: { $0.id.uuidString == medicationID }) else {
            return "I could not find that medication."
        }

        apply(status, to: &medications[index], doseTime: doseTime)
        saveMedications(medications)

        if status == .taken {
            return "Marked \(medications[index].siriNickname) at \(doseTime) as taken."
        }

        return "Marked \(medications[index].siriNickname) at \(doseTime) as not sure."
    }

    nonisolated static func dueMedicationsSummary() -> String {
        let dueDoseNames = loadMedications()
            .filter { $0.isScheduled(on: Date()) }
            .flatMap { medication in
                medication.displayDoseTimes.compactMap { doseTime -> String? in
                    guard medication.doseStatus(for: doseTime, on: Date()) == .due else {
                        return nil
                    }

                    return "\(medication.siriNickname) at \(doseTime)"
                }
            }

        guard !dueDoseNames.isEmpty else {
            return "No medications are still due today."
        }

        return "Still due today: \(dueDoseNames.joined(separator: ", "))."
    }

    nonisolated private static func doseTimeToLog(from doseTimes: [String]) -> DoseSelection {
        let sortedDoseTimes = doseTimes.sorted { first, second in
            dateToday(from: first) ?? .distantFuture < dateToday(from: second) ?? .distantFuture
        }

        guard !sortedDoseTimes.isEmpty else {
            return DoseSelection(doseTime: nil, candidateDoseTimes: [], needsChoice: false, message: "All doses for {medication} are already logged today.")
        }

        let now = Date()
        let relevantDoseTimes = sortedDoseTimes.filter { doseTime in
            guard let doseDate = dateToday(from: doseTime) else {
                return false
            }

            return doseDate <= now.addingTimeInterval(3_600)
        }

        if relevantDoseTimes.count > 1 {
            return DoseSelection(doseTime: nil, candidateDoseTimes: relevantDoseTimes, needsChoice: true, message: nil)
        }

        if let doseTime = relevantDoseTimes.first {
            return DoseSelection(doseTime: doseTime, candidateDoseTimes: [doseTime], needsChoice: false, message: nil)
        }

        return DoseSelection(doseTime: sortedDoseTimes.first, candidateDoseTimes: sortedDoseTimes, needsChoice: false, message: nil)
    }

    nonisolated private static func dateToday(from time: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"

        guard let parsedTime = formatter.date(from: time) else {
            return nil
        }

        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: parsedTime)
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())

        var components = DateComponents()
        components.year = todayComponents.year
        components.month = todayComponents.month
        components.day = todayComponents.day
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute

        return calendar.date(from: components)
    }

    nonisolated private static func matchingMedicationIndex(for spokenName: String, in medications: [Medication]) -> (index: Int?, message: String) {
        let searchText = normalized(spokenName)

        guard !searchText.isEmpty else {
            return (nil, "I did not hear the medication name.")
        }

        let exactMatches = medications.indices.filter { index in
            normalized(medications[index].siriNickname) == searchText ||
                normalized(medications[index].realName) == searchText
        }

        if exactMatches.count == 1, let index = exactMatches.first {
            return (index, "")
        }

        if exactMatches.count > 1 {
            return (nil, "More than one medication matches that name.")
        }

        let partialMatches = medications.indices.filter { index in
            let siriName = normalized(medications[index].siriNickname)
            let realName = normalized(medications[index].realName)
            return siriName.contains(searchText) ||
                searchText.contains(siriName) ||
                realName.contains(searchText) ||
                searchText.contains(realName)
        }

        if partialMatches.count == 1, let index = partialMatches.first {
            return (index, "")
        }

        if partialMatches.count > 1 {
            return (nil, "More than one medication matches that name.")
        }

        return (nil, "I could not find \(spokenName) in Pill Tracker.")
    }

    nonisolated private static func normalized(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    nonisolated private static func loadMedications() -> [Medication] {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let medications = try? JSONDecoder().decode([Medication].self, from: data)
        else {
            return []
        }

        return medications
    }

    nonisolated private static func saveMedications(_ medications: [Medication]) {
        guard let data = try? JSONEncoder().encode(medications) else {
            return
        }

        UserDefaults.standard.set(data, forKey: storageKey)
        NotificationCenter.default.post(name: .medicationsDidChangeExternally, object: nil)
    }

    nonisolated private static func apply(_ status: DoseStatus, to medication: inout Medication, doseTime: String) {
        let todayKey = DoseHistory.dateKey(for: Date())
        var todaysStatuses = medication.doseStatusHistory[todayKey] ?? [:]
        var todaysUpdatedAt = medication.doseStatusUpdatedAtHistory[todayKey] ?? [:]
        var todaysLog = medication.doseStatusLogHistory[todayKey] ?? [:]

        switch status {
        case .taken:
            medication.unsureDoseTimesToday.removeAll { $0 == doseTime }

            if !medication.takenDoseTimesToday.contains(doseTime) {
                medication.takenDoseTimesToday.append(doseTime)
            }

            todaysStatuses[doseTime] = DoseStatus.taken.rawValue
            todaysUpdatedAt[doseTime] = Date()
            addLogEntry(DoseStatus.taken.rawValue, doseTime: doseTime, todaysLog: &todaysLog)
        case .unsure:
            medication.takenDoseTimesToday.removeAll { $0 == doseTime }

            if !medication.unsureDoseTimesToday.contains(doseTime) {
                medication.unsureDoseTimesToday.append(doseTime)
            }

            todaysStatuses[doseTime] = DoseStatus.unsure.rawValue
            todaysUpdatedAt[doseTime] = Date()
            addLogEntry(DoseStatus.unsure.rawValue, doseTime: doseTime, todaysLog: &todaysLog)
        case .due:
            medication.takenDoseTimesToday.removeAll { $0 == doseTime }
            medication.unsureDoseTimesToday.removeAll { $0 == doseTime }
            todaysStatuses.removeValue(forKey: doseTime)
            todaysUpdatedAt.removeValue(forKey: doseTime)
            addLogEntry("Cleared", doseTime: doseTime, todaysLog: &todaysLog)
        }

        medication.doseStatusHistory[todayKey] = todaysStatuses.isEmpty ? nil : todaysStatuses
        medication.doseStatusUpdatedAtHistory[todayKey] = todaysUpdatedAt.isEmpty ? nil : todaysUpdatedAt
        medication.doseStatusLogHistory[todayKey] = todaysLog.isEmpty ? nil : todaysLog
    }

    nonisolated private static func addLogEntry(_ status: String, doseTime: String, todaysLog: inout [String: [DoseStatusLogEntry]]) {
        var entries = todaysLog[doseTime] ?? []
        entries.append(DoseStatusLogEntry(status: status, changedAt: Date()))
        todaysLog[doseTime] = Array(entries.suffix(20))
    }
}
