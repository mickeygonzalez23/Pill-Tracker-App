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

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct MedicationEntityQuery: EntityQuery {
    func entities(for identifiers: [MedicationEntity.ID]) async throws -> [MedicationEntity] {
        MedicationIntentStore.medicationEntities().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [MedicationEntity] {
        MedicationIntentStore.medicationEntities()
    }

    func defaultResult() async -> MedicationEntity? {
        MedicationIntentStore.medicationEntities().first
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
    static var description = IntentDescription("Marks today's doses for a medication as taken using its private Siri name.")
    static var openAppWhenRun = false

    @Parameter(title: "Medication")
    var medication: MedicationEntity

    init() {
        medication = MedicationEntity(id: "", name: "")
    }

    init(medication: MedicationEntity) {
        self.medication = medication
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = MedicationIntentStore.markMedication(id: medication.id, as: .taken)
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

struct MarkMedicationUnsureIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Medication Not Sure"
    static var description = IntentDescription("Marks today's doses for a medication as not sure using its private Siri name.")
    static var openAppWhenRun = false

    @Parameter(title: "Medication")
    var medication: MedicationEntity

    init() {
        medication = MedicationEntity(id: "", name: "")
    }

    init(medication: MedicationEntity) {
        self.medication = medication
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = MedicationIntentStore.markMedication(id: medication.id, as: .unsure)
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

struct MarkDoseNumberTakenIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Dose Number Taken"
    static var description = IntentDescription("Marks a first, second, third, or later dose as taken for today's scheduled medications.")
    static var openAppWhenRun = false

    @Parameter(title: "Dose Number")
    var doseNumber: DoseNumber

    init() {
        doseNumber = .first
    }

    init(doseNumber: DoseNumber) {
        self.doseNumber = doseNumber
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = MedicationIntentStore.markDoseNumber(doseNumber, as: .taken)
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

struct CheckDueMedicationsIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Due Medications"
    static var description = IntentDescription("Checks which medications are still due today.")
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
            intent: MarkDoseNumberTakenIntent(),
            phrases: [
                "I took my \(\.$doseNumber) dose today in \(.applicationName)",
                "Mark my \(\.$doseNumber) dose as taken in \(.applicationName)"
            ],
            shortTitle: "Mark Dose",
            systemImageName: "checkmark.circle.fill"
        )

        AppShortcut(
            intent: CheckDueMedicationsIntent(),
            phrases: [
                "Did I take my pills in \(.applicationName)",
                "What's due in \(.applicationName)",
                "What meds are due in \(.applicationName)"
            ],
            shortTitle: "What's Due",
            systemImageName: "clock"
        )
    }
}

enum MedicationIntentStore {
    nonisolated private static let storageKey = "savedMedications"

    nonisolated static func medicationEntities() -> [MedicationEntity] {
        loadMedications().map {
            MedicationEntity(id: $0.id.uuidString, name: $0.siriNickname)
        }
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
        let todayKey = DoseHistory.dateKey(for: Date())
        var todaysStatuses = medications[index].doseStatusHistory[todayKey] ?? [:]

        switch status {
        case .taken:
            medications[index].takenDoseTimesToday = doseTimes
            medications[index].unsureDoseTimesToday = []
            doseTimes.forEach { todaysStatuses[$0] = DoseStatus.taken.rawValue }
        case .unsure:
            medications[index].takenDoseTimesToday = []
            medications[index].unsureDoseTimesToday = doseTimes
            doseTimes.forEach { todaysStatuses[$0] = DoseStatus.unsure.rawValue }
        case .due:
            medications[index].takenDoseTimesToday = []
            medications[index].unsureDoseTimesToday = []
            doseTimes.forEach { todaysStatuses.removeValue(forKey: $0) }
        }

        medications[index].doseStatusHistory[todayKey] = todaysStatuses.isEmpty ? nil : todaysStatuses
        saveMedications(medications)

        if status == .taken {
            return "Marked \(medications[index].siriNickname) as taken for today."
        }

        return "Marked \(medications[index].siriNickname) as not sure for today."
    }

    nonisolated static func markDoseNumber(_ doseNumber: DoseNumber, as status: DoseStatus) -> String {
        var medications = loadMedications()
        let todayKey = DoseHistory.dateKey(for: Date())
        var updatedDoseNames: [String] = []

        for index in medications.indices where medications[index].isScheduled(on: Date()) {
            let doseTimes = medications[index].displayDoseTimes

            guard doseTimes.indices.contains(doseNumber.index) else {
                continue
            }

            let doseTime = doseTimes[doseNumber.index]
            var todaysStatuses = medications[index].doseStatusHistory[todayKey] ?? [:]

            switch status {
            case .taken:
                medications[index].unsureDoseTimesToday.removeAll { $0 == doseTime }

                if !medications[index].takenDoseTimesToday.contains(doseTime) {
                    medications[index].takenDoseTimesToday.append(doseTime)
                }

                todaysStatuses[doseTime] = DoseStatus.taken.rawValue
            case .unsure:
                medications[index].takenDoseTimesToday.removeAll { $0 == doseTime }

                if !medications[index].unsureDoseTimesToday.contains(doseTime) {
                    medications[index].unsureDoseTimesToday.append(doseTime)
                }

                todaysStatuses[doseTime] = DoseStatus.unsure.rawValue
            case .due:
                medications[index].takenDoseTimesToday.removeAll { $0 == doseTime }
                medications[index].unsureDoseTimesToday.removeAll { $0 == doseTime }
                todaysStatuses.removeValue(forKey: doseTime)
            }

            medications[index].doseStatusHistory[todayKey] = todaysStatuses.isEmpty ? nil : todaysStatuses
            updatedDoseNames.append("\(medications[index].siriNickname) at \(doseTime)")
        }

        guard !updatedDoseNames.isEmpty else {
            return "I could not find a \(doseNumber.rawValue) dose scheduled for today."
        }

        saveMedications(medications)
        return "Marked your \(doseNumber.rawValue) dose as taken: \(updatedDoseNames.joined(separator: ", "))."
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
    }
}
