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

enum DoseNumber: String, AppEnum {
    case first
    case second
    case third
    case fourth
    case fifth
    case sixth
    case seventh
    case eighth
    case ninth
    case tenth
    case eleventh
    case twelfth

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Dose Number")
    static var caseDisplayRepresentations: [DoseNumber: DisplayRepresentation] = [
        .first: "Dose 1",
        .second: "Dose 2",
        .third: "Dose 3",
        .fourth: "Dose 4",
        .fifth: "Dose 5",
        .sixth: "Dose 6",
        .seventh: "Dose 7",
        .eighth: "Dose 8",
        .ninth: "Dose 9",
        .tenth: "Dose 10",
        .eleventh: "Dose 11",
        .twelfth: "Dose 12"
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
        case .seventh:
            return 6
        case .eighth:
            return 7
        case .ninth:
            return 8
        case .tenth:
            return 9
        case .eleventh:
            return 10
        case .twelfth:
            return 11
        }
    }
}

struct MarkMedicationTakenIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Medication Taken"
    static var description = IntentDescription("Marks the next relevant dose for a medication as taken using its private medication nickname.")
    static var openAppWhenRun = false

    @Parameter(title: "Medication")
    var medication: MedicationEntity

    @Parameter(title: "Dose")
    var doseNumber: DoseNumber?

    init() {
        medication = MedicationEntity(id: "", name: "", realName: "")
        doseNumber = nil
    }

    init(medication: MedicationEntity) {
        self.medication = medication
        doseNumber = nil
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = try await markDose(as: .taken)
        return .result(dialog: IntentDialog(stringLiteral: message))
    }

    private func markDose(as status: DoseStatus) async throws -> String {
        let selection = MedicationIntentStore.doseSelection(for: medication.id, selectedDoseNumber: doseNumber)

        if let message = selection.message {
            return message
        }

        if selection.needsChoice {
            let selectedDoseNumber = try await $doseNumber.requestDisambiguation(
                among: selection.candidateDoseNumbers,
                dialog: IntentDialog(stringLiteral: selection.choicePrompt ?? "Which dose?")
            )
            return MedicationIntentStore.markMedicationDoseNumberWithMessage(
                id: medication.id,
                doseNumber: selectedDoseNumber,
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
    static var description = IntentDescription("Marks the next relevant dose for a medication as not sure using its private medication nickname.")
    static var openAppWhenRun = false

    @Parameter(title: "Medication")
    var medication: MedicationEntity

    @Parameter(title: "Dose")
    var doseNumber: DoseNumber?

    init() {
        medication = MedicationEntity(id: "", name: "", realName: "")
        doseNumber = nil
    }

    init(medication: MedicationEntity) {
        self.medication = medication
        doseNumber = nil
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = try await markDose(as: .unsure)
        return .result(dialog: IntentDialog(stringLiteral: message))
    }

    private func markDose(as status: DoseStatus) async throws -> String {
        let selection = MedicationIntentStore.doseSelection(for: medication.id, selectedDoseNumber: doseNumber)

        if let message = selection.message {
            return message
        }

        if selection.needsChoice {
            let selectedDoseNumber = try await $doseNumber.requestDisambiguation(
                among: selection.candidateDoseNumbers,
                dialog: IntentDialog(stringLiteral: selection.choicePrompt ?? "Which dose?")
            )
            return MedicationIntentStore.markMedicationDoseNumberWithMessage(
                id: medication.id,
                doseNumber: selectedDoseNumber,
                as: status
            )
        }

        guard let doseTime = selection.doseTime else {
            return "I could not find a dose to log."
        }

        return MedicationIntentStore.markMedicationDoseWithMessage(id: medication.id, doseTime: doseTime, as: status)
    }
}

struct MarkMedicationSkippedIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Medication Skipped"
    static var description = IntentDescription("Marks the next relevant dose for a medication as skipped using its private medication nickname.")
    static var openAppWhenRun = false

    @Parameter(title: "Medication") var medication: MedicationEntity
    @Parameter(title: "Dose") var doseNumber: DoseNumber?

    init() {
        medication = MedicationEntity(id: "", name: "", realName: "")
        doseNumber = nil
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let selection = MedicationIntentStore.doseSelection(for: medication.id, selectedDoseNumber: doseNumber)
        if let message = selection.message { return .result(dialog: IntentDialog(stringLiteral: message)) }
        if selection.needsChoice {
            let selected = try await $doseNumber.requestDisambiguation(
                among: selection.candidateDoseNumbers,
                dialog: IntentDialog(stringLiteral: selection.choicePrompt ?? "Which dose?")
            )
            try await requestConfirmation(
                actionName: .continue,
                dialog: "Confirm marking this dose as skipped."
            )
            return .result(dialog: IntentDialog(stringLiteral: MedicationIntentStore.markMedicationDoseNumberWithMessage(id: medication.id, doseNumber: selected, as: .skipped)))
        }
        guard let doseTime = selection.doseTime else {
            return .result(dialog: "I could not find a dose to log.")
        }
        try await requestConfirmation(
            actionName: .continue,
            dialog: "Confirm marking \(medication.name) at \(doseTime) as skipped."
        )
        return .result(dialog: IntentDialog(stringLiteral: MedicationIntentStore.markMedicationDoseWithMessage(id: medication.id, doseTime: doseTime, as: .skipped)))
    }
}
struct CheckDueMedicationsIntent: AppIntent {
    static var title: LocalizedStringResource = "Did I Take My Pills?"
    static var description = IntentDescription("Gives today's status for each scheduled medication dose without changing it.")
    static var openAppWhenRun = false

    @Parameter(title: "Medication")
    var medication: MedicationEntity?

    init() {
        medication = nil
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = MedicationIntentStore.medicationsStatusSummary(medicationID: medication?.id)
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

struct PillTrackerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CheckDueMedicationsIntent(),
            phrases: [
                "Did I take my pills in \(.applicationName)?",
                "Did I take \(\.$medication) in \(.applicationName)?",
                "Check my medication status in \(.applicationName)",
                "\(.applicationName) status report"
            ],
            shortTitle: "Did I Take My Pills?",
            systemImageName: "list.bullet.clipboard"
        )

        AppShortcut(
            intent: MarkMedicationTakenIntent(),
            phrases: [
                "Mark \(\.$medication) as taken in \(.applicationName)"
            ],
            shortTitle: "Mark Taken",
            systemImageName: "checkmark.circle"
        )

        AppShortcut(
            intent: MarkMedicationUnsureIntent(),
            phrases: [
                "Mark \(\.$medication) as not sure in \(.applicationName)"
            ],
            shortTitle: "Not Sure",
            systemImageName: "questionmark.circle"
        )

        AppShortcut(
            intent: MarkMedicationSkippedIntent(),
            phrases: [
                "Mark \(\.$medication) as skipped in \(.applicationName)"
            ],
            shortTitle: "Skipped",
            systemImageName: "forward.circle"
        )

    }
}

enum MedicationIntentStore {
    nonisolated private static let storageKey = "savedMedications"

    struct DoseSelection {
        var doseTime: String?
        var candidateDoseNumbers: [DoseNumber]
        var needsChoice: Bool
        var choicePrompt: String?
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

        let doseTimes = medications[index].doseTimes(on: Date())
        for doseTime in doseTimes {
            apply(status, to: &medications[index], doseTime: doseTime)
        }
        saveMedications(medications)

        return "Marked \(medications[index].siriNickname) as \(spokenStatus(status)) for today."
    }

    nonisolated static func markNextMedicationDose(id medicationID: String, as status: DoseStatus) -> String {
        let selection = doseSelection(for: medicationID, selectedDoseNumber: nil)

        if let message = selection.message {
            return message
        }

        guard let doseTime = selection.doseTime, !selection.needsChoice else {
            return "Please choose which dose to log."
        }

        return markMedicationDoseWithMessage(id: medicationID, doseTime: doseTime, as: status)
    }

    nonisolated static func doseSelection(for medicationID: String, selectedDoseNumber: DoseNumber?) -> DoseSelection {
        let medications = loadMedications()

        guard let index = medications.firstIndex(where: { $0.id.uuidString == medicationID }) else {
            return DoseSelection(doseTime: nil, candidateDoseNumbers: [], needsChoice: false, choicePrompt: nil, message: "I could not find that medication.")
        }

        guard medications[index].isScheduled(on: Date()) else {
            return DoseSelection(doseTime: nil, candidateDoseNumbers: [], needsChoice: false, choicePrompt: nil, message: "\(medications[index].siriNickname) is not scheduled for today.")
        }

        let doseTimes = medications[index].doseTimes(on: Date())
        let unloggedDoseTimes = doseTimes.filter {
            medications[index].doseStatus(for: $0, on: Date()) == .due
        }

        if let selectedDoseNumber {
            guard doseTimes.indices.contains(selectedDoseNumber.index) else {
                return DoseSelection(doseTime: nil, candidateDoseNumbers: [], needsChoice: false, choicePrompt: nil, message: "\(medications[index].siriNickname) does not have Dose \(selectedDoseNumber.index + 1) scheduled today.")
            }

            let selectedDoseTime = doseTimes[selectedDoseNumber.index]

            guard unloggedDoseTimes.contains(selectedDoseTime) else {
                return DoseSelection(doseTime: nil, candidateDoseNumbers: [], needsChoice: false, choicePrompt: nil, message: "\(medications[index].siriNickname)'s Dose \(selectedDoseNumber.index + 1) at \(selectedDoseTime) is already logged today.")
            }

            return DoseSelection(doseTime: selectedDoseTime, candidateDoseNumbers: [selectedDoseNumber], needsChoice: false, choicePrompt: nil, message: nil)
        }

        let doseSelection = doseTimeToLog(from: unloggedDoseTimes, scheduledDoseTimes: doseTimes)

        if let message = doseSelection.message {
            return DoseSelection(
                doseTime: nil,
                candidateDoseNumbers: doseSelection.candidateDoseNumbers,
                needsChoice: doseSelection.needsChoice,
                choicePrompt: doseSelection.choicePrompt,
                message: message.replacingOccurrences(of: "{medication}", with: medications[index].siriNickname)
            )
        }

        return doseSelection
    }

    nonisolated static func markMedicationDose(id medicationID: String, doseTime: String, as status: DoseStatus) {
        _ = markMedicationDoseWithMessage(id: medicationID, doseTime: doseTime, as: status)
    }

    nonisolated static func markMedicationDoseNumberWithMessage(id medicationID: String, doseNumber: DoseNumber, as status: DoseStatus) -> String {
        let selection = doseSelection(for: medicationID, selectedDoseNumber: doseNumber)

        if let message = selection.message {
            return message
        }

        guard let doseTime = selection.doseTime else {
            return "I could not find a dose to log."
        }

        return markMedicationDoseWithMessage(id: medicationID, doseTime: doseTime, as: status)
    }

    nonisolated static func markMedicationDoseWithMessage(id medicationID: String, doseTime: String, as status: DoseStatus) -> String {
        var medications = loadMedications()

        guard let index = medications.firstIndex(where: { $0.id.uuidString == medicationID }) else {
            return "I could not find that medication."
        }

        apply(status, to: &medications[index], doseTime: doseTime)
        saveMedications(medications)

        return "Marked \(medications[index].siriNickname) at \(doseTime) as \(spokenStatus(status))."
    }

    nonisolated static func medicationsStatusSummary(medicationID: String? = nil) -> String {
        let medications = loadMedications().filter { medication in
            medicationID == nil || medication.id.uuidString == medicationID
        }
        let statuses = medications
            .filter { $0.isScheduled(on: Date()) }
            .flatMap { medication in
                medication.doseTimes(on: Date()).map { doseTime in
                    let status = medication.doseStatus(for: doseTime, on: Date())
                    return "\(medication.siriNickname) at \(doseTime) is \(spokenStatus(status))"
                }
            }

        guard !statuses.isEmpty else {
            return medicationID == nil ? "No medications are scheduled for today." : "That medication is not scheduled for today."
        }

        return "Today's medication status: \(statuses.joined(separator: ", "))."
    }

    nonisolated private static func doseTimeToLog(from doseTimes: [String], scheduledDoseTimes: [String]) -> DoseSelection {
        let sortedDoseTimes = doseTimes.sorted { first, second in
            dateToday(from: first) ?? .distantFuture < dateToday(from: second) ?? .distantFuture
        }

        guard !sortedDoseTimes.isEmpty else {
            return DoseSelection(doseTime: nil, candidateDoseNumbers: [], needsChoice: false, choicePrompt: nil, message: "All doses for {medication} are already logged today.")
        }

        let now = Date()
        let relevantDoseTimes = sortedDoseTimes.filter { doseTime in
            guard let doseDate = dateToday(from: doseTime) else {
                return false
            }

            return doseDate <= now.addingTimeInterval(3_600)
        }

        if relevantDoseTimes.count > 1 {
            let candidateDoseNumbers = doseNumbers(for: relevantDoseTimes, scheduledDoseTimes: scheduledDoseTimes)
            let prompt = doseChoicePrompt(for: candidateDoseNumbers, scheduledDoseTimes: scheduledDoseTimes)
            return DoseSelection(doseTime: nil, candidateDoseNumbers: candidateDoseNumbers, needsChoice: true, choicePrompt: prompt, message: nil)
        }

        if let doseTime = relevantDoseTimes.first {
            return DoseSelection(doseTime: doseTime, candidateDoseNumbers: doseNumbers(for: [doseTime], scheduledDoseTimes: scheduledDoseTimes), needsChoice: false, choicePrompt: nil, message: nil)
        }

        return DoseSelection(doseTime: sortedDoseTimes.first, candidateDoseNumbers: doseNumbers(for: sortedDoseTimes, scheduledDoseTimes: scheduledDoseTimes), needsChoice: false, choicePrompt: nil, message: nil)
    }

    nonisolated private static func doseNumbers(for doseTimes: [String], scheduledDoseTimes: [String]) -> [DoseNumber] {
        doseTimes.compactMap { doseTime in
            guard let index = scheduledDoseTimes.firstIndex(of: doseTime) else {
                return nil
            }

            return DoseNumber.allCases.first { $0.index == index }
        }
    }

    nonisolated private static func doseChoicePrompt(for doseNumbers: [DoseNumber], scheduledDoseTimes: [String]) -> String {
        let choices = doseNumbers.compactMap { doseNumber -> String? in
            guard scheduledDoseTimes.indices.contains(doseNumber.index) else {
                return nil
            }

            return "Dose \(doseNumber.index + 1) at \(scheduledDoseTimes[doseNumber.index])"
        }

        return "Which dose? \(choices.joined(separator: ", "))."
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

    nonisolated private static func spokenStatus(_ status: DoseStatus) -> String {
        switch status {
        case .taken: return "taken"
        case .unsure: return "not sure"
        case .skipped: return "skipped"
        case .due: return "due"
        }
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
        medication.setDoseStatus(status == .due ? nil : status, for: doseTime)
    }
}
