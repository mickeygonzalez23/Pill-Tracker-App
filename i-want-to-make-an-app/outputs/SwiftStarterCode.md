# Med Fed Pill Tracker Swift Starter Code

This is starter code for the future Xcode project. It is not a complete app yet, but it gives the iOS build a clear shape.

## Medication.swift

```swift
import Foundation
import SwiftData

@Model
final class Medication {
    var realName: String
    var dose: String
    var siriNickname: String
    var scheduledTime: Date
    var reminderEnabled: Bool
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        realName: String,
        dose: String,
        siriNickname: String,
        scheduledTime: Date,
        reminderEnabled: Bool = true
    ) {
        self.realName = realName
        self.dose = dose
        self.siriNickname = siriNickname
        self.scheduledTime = scheduledTime
        self.reminderEnabled = reminderEnabled
        self.isArchived = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
```

## MedicationLog.swift

```swift
import Foundation
import SwiftData

enum MedicationLogSource: String, Codable, CaseIterable {
    case manual
    case siriUnlocked
    case siriLocked
    case notification
}

enum MedicationLogStatus: String, Codable, CaseIterable {
    case taken
    case skipped
    case missed
    case undone
}

@Model
final class MedicationLog {
    var medicationID: PersistentIdentifier?
    var medicationNickname: String
    var takenAt: Date
    var source: MedicationLogSource
    var status: MedicationLogStatus
    var createdAt: Date

    init(
        medication: Medication,
        takenAt: Date = Date(),
        source: MedicationLogSource,
        status: MedicationLogStatus = .taken
    ) {
        self.medicationID = medication.persistentModelID
        self.medicationNickname = medication.siriNickname
        self.takenAt = takenAt
        self.source = source
        self.status = status
        self.createdAt = Date()
    }
}
```

## NicknameValidator.swift

```swift
import Foundation

struct NicknameValidator {
    static func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .lowercased()
    }

    static func isDuplicate(_ nickname: String, existingNicknames: [String]) -> Bool {
        let normalizedNickname = normalized(nickname)
        return existingNicknames.map(normalized).contains(normalizedNickname)
    }
}
```

## MedicationEntity.swift

```swift
import AppIntents
import Foundation

struct MedicationEntity: AppEntity, Identifiable {
    let id: String
    let realName: String
    let siriNickname: String

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Medication")
    static var defaultQuery = MedicationEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(siriNickname)")
    }
}
```

## MedicationEntityQuery.swift

```swift
import AppIntents
import Foundation

struct MedicationEntityQuery: EntityStringQuery {
    func entities(for identifiers: [MedicationEntity.ID]) async throws -> [MedicationEntity] {
        let medications = try await MedicationIntentStore.shared.allMedicationEntities()
        return medications.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [MedicationEntity] {
        try await MedicationIntentStore.shared.dueMedicationEntities()
    }

    func entities(matching string: String) async throws -> [MedicationEntity] {
        let search = NicknameValidator.normalized(string)
        let medications = try await MedicationIntentStore.shared.allMedicationEntities()

        return medications.filter {
            NicknameValidator.normalized($0.siriNickname) == search
        }
    }
}
```

## MarkMedicationTakenIntent.swift

```swift
import AppIntents
import Foundation

struct MarkMedicationTakenIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Medication Taken"
    static var description = IntentDescription("Marks a medication as taken using its Siri-safe nickname.")
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Medication")
    var medication: MedicationEntity

    func perform() async throws -> some IntentResult {
        try await MedicationIntentStore.shared.markTaken(
            medicationID: medication.id,
            source: .siriLocked
        )

        return .result(dialog: "Marked \(medication.siriNickname) as taken.")
    }
}
```

## MarkAllDueMedicationsTakenIntent.swift

```swift
import AppIntents
import Foundation

struct MarkAllDueMedicationsTakenIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark All Due Medications Taken"
    static var description = IntentDescription("Marks all currently due medications as taken.")
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        let count = try await MedicationIntentStore.shared.markAllDueTaken(source: .siriLocked)

        if count == 0 {
            return .result(dialog: "You do not have any medications due right now.")
        }

        if count == 1 {
            return .result(dialog: "Marked 1 medication as taken.")
        }

        return .result(dialog: "Marked \(count) medications as taken.")
    }
}
```

## MedicationShortcuts.swift

```swift
import AppIntents

struct MedicationShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .green

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: MarkMedicationTakenIntent(),
            phrases: [
                "I took \(\.$medication) in \(.applicationName)",
                "I took my \(\.$medication) in \(.applicationName)",
                "Mark \(\.$medication) as taken in \(.applicationName)",
                "Log \(\.$medication) in \(.applicationName)"
            ],
            shortTitle: "Mark Medication",
            systemImageName: "pills"
        )

        AppShortcut(
            intent: MarkAllDueMedicationsTakenIntent(),
            phrases: [
                "I took my medication in \(.applicationName)",
                "I took my meds in \(.applicationName)",
                "I took all of my medication in \(.applicationName)",
                "I took all of my meds in \(.applicationName)",
                "Mark all due meds as taken in \(.applicationName)"
            ],
            shortTitle: "Mark All Due",
            systemImageName: "checkmark.circle"
        )
    }
}
```

## MedicationIntentStore.swift

```swift
import Foundation

actor MedicationIntentStore {
    static let shared = MedicationIntentStore()

    func allMedicationEntities() async throws -> [MedicationEntity] {
        // Connect this to SwiftData in the Xcode project.
        []
    }

    func dueMedicationEntities() async throws -> [MedicationEntity] {
        // Return only medications currently due.
        []
    }

    func markTaken(medicationID: String, source: MedicationLogSource) async throws {
        // Find the medication by ID and create a MedicationLog.
    }

    func markAllDueTaken(source: MedicationLogSource) async throws -> Int {
        // Create logs for all due medications and return the count.
        0
    }
}
```

## Important Note

The `MedicationIntentStore` placeholder will need real SwiftData access once the Xcode project exists. The rest of the structure gives us the names, behavior, and Siri privacy rules to build around.

