# Did I Take It? Pill Tracker Dose-Specific Siri Starter Code

Use this when one medication has multiple doses in the same day.

Supported phrases:

```text
Hey Siri, I took sugar pill dose 1.
Hey Siri, I took sugar pill dose 2.
Hey Siri, I took my morning sugar pill.
Hey Siri, I took my evening sugar pill.
```

## MarkMedicationDoseTakenIntent.swift

```swift
import AppIntents
import Foundation

struct MarkMedicationDoseTakenIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Medication Dose Taken"
    static var description = IntentDescription("Marks a specific medication dose as taken.")
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Medication")
    var medication: MedicationEntity

    @Parameter(title: "Dose Number")
    var doseNumber: Int

    func perform() async throws -> some IntentResult {
        try await MedicationIntentStore.shared.markDoseTaken(
            medicationID: medication.id,
            doseNumber: doseNumber,
            source: .siriLocked
        )

        return .result(
            dialog: "Marked \(medication.siriNickname) dose \(doseNumber) as taken."
        )
    }
}
```

## MarkMedicationDoseTimeTakenIntent.swift

```swift
import AppIntents
import Foundation

struct MarkMedicationDoseTimeTakenIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Medication Dose Time Taken"
    static var description = IntentDescription("Marks a medication dose time as taken.")
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Medication")
    var medication: MedicationEntity

    @Parameter(title: "Dose Time")
    var doseTime: DoseTimeEntity

    func perform() async throws -> some IntentResult {
        try await MedicationIntentStore.shared.markDoseTimeTaken(
            medicationID: medication.id,
            doseTimeID: doseTime.id,
            source: .siriLocked
        )

        return .result(
            dialog: "Marked \(doseTime.displayName.lowercased()) \(medication.siriNickname) as taken."
        )
    }
}
```

## DoseTimeEntity.swift

```swift
import AppIntents
import Foundation

struct DoseTimeEntity: AppEntity, Identifiable {
    let id: String
    let displayName: String

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Dose Time")
    static var defaultQuery = DoseTimeEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayName)")
    }
}
```

## DoseTimeEntityQuery.swift

```swift
import AppIntents
import Foundation

struct DoseTimeEntityQuery: EntityStringQuery {
    private let doseTimes = [
        DoseTimeEntity(id: "morning", displayName: "Morning"),
        DoseTimeEntity(id: "noon", displayName: "Noon"),
        DoseTimeEntity(id: "evening", displayName: "Evening"),
        DoseTimeEntity(id: "bedtime", displayName: "Bedtime")
    ]

    func entities(for identifiers: [DoseTimeEntity.ID]) async throws -> [DoseTimeEntity] {
        doseTimes.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [DoseTimeEntity] {
        doseTimes
    }

    func entities(matching string: String) async throws -> [DoseTimeEntity] {
        let search = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return doseTimes.filter {
            $0.displayName.lowercased() == search || $0.id == search
        }
    }
}
```

## MedicationIntentStore Additions

```swift
func markDoseTaken(
    medicationID: String,
    doseNumber: Int,
    source: MedicationLogSource
) async throws {
    // Validate doseNumber exists for this medication.
    // Create a MedicationLog for that specific dose.
}

func markDoseTimeTaken(
    medicationID: String,
    doseTimeID: String,
    source: MedicationLogSource
) async throws {
    // Validate the medication has this dose time today.
    // Create a MedicationLog for that specific dose time.
}
```

## Privacy Rule

When the iPhone is locked, Siri can say:

```text
Marked sugar pill dose 2 as taken.
Marked evening sugar pill as taken.
```

Siri should not say:

```text
Marked Metformin 500 mg as taken.
```

