# Medication Siri MVP

## Goal

Build an iPhone app that lets a user mark medication as taken by speaking to Siri, including while the iPhone is locked, without Siri saying the real medication name aloud.

## Key Idea

Each medication can have a user-created Siri-safe nickname.

Example:

| Real medication name | Siri nickname |
| --- | --- |
| Metformin | Sugar pill |
| Lisinopril | Morning pill |
| Atorvastatin | Night pill |

The user can then say:

```text
Hey Siri, I took my sugar pill.
Hey Siri, mark morning pill as taken.
Hey Siri, log my night pill.
```

Siri replies with only the nickname:

```text
Marked sugar pill as taken.
```

## Privacy Rules

- Siri should use the nickname, not the real medication name.
- Nicknames must be unique.
- If the phone is locked, the app should avoid showing or speaking sensitive medication details.
- If a medication has no nickname, locked Siri commands should use generic labels like "medication 1."
- The real medication name is shown only inside the app.

## MVP Screens

1. Today
   - Shows medications due today.
   - Lets the user mark a medication as taken.
   - Shows taken, due, missed, or skipped status.

2. Medications
   - Lists saved medications.
   - Lets the user add, edit, or delete medications.

3. Medication Detail
   - Real medication name.
   - Dose.
   - Frequency.
   - Dose times.
   - Siri nickname.
   - Reminder settings.

4. History
   - Shows medication logs.
   - Lets the user undo an accidental log.

## Siri Phrases

```text
Hey Siri, I took my medication.
Hey Siri, I took my meds.
Hey Siri, I took all of my medication.
Hey Siri, I took all of my meds.
Hey Siri, I took my sugar pill.
Hey Siri, mark sugar pill as taken.
Hey Siri, log my morning pill.
Hey Siri, I took my night pill.
Hey Siri, mark all due meds as taken.
```

## Recommended Locked Phone Behavior

When the user says:

```text
Hey Siri, I took my sugar pill.
```

The app should:

1. Match "sugar pill" to the medication's Siri nickname.
2. Add a taken log for the current date and time.
3. Return a short spoken confirmation.

```text
Marked sugar pill as taken.
```

If there is ambiguity:

```text
I found more than one match. Please open the app to choose.
```

If there is no match:

```text
I could not find that medication nickname.
```

## Swift App Intent Starter

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
        try await MedicationStore.shared.markTaken(medicationID: medication.id)

        return .result(
            dialog: "Marked \(medication.siriNickname) as taken."
        )
    }
}
```

## Medication Entity Starter

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

## Medication Query Starter

```swift
import AppIntents
import Foundation

struct MedicationEntityQuery: EntityQuery {
    func entities(for identifiers: [MedicationEntity.ID]) async throws -> [MedicationEntity] {
        let medications = try await MedicationStore.shared.allMedications()
        return medications.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [MedicationEntity] {
        try await MedicationStore.shared.dueMedications()
    }

    func entities(matching string: String) async throws -> [MedicationEntity] {
        let medications = try await MedicationStore.shared.allMedications()
        let normalizedSearch = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return medications.filter {
            $0.siriNickname.lowercased() == normalizedSearch
        }
    }
}
```

## App Shortcuts Starter

```swift
import AppIntents

struct MedicationShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: MarkMedicationTakenIntent(),
            phrases: [
                "I took \(\.$medication)",
                "I took my \(\.$medication)",
                "Mark \(\.$medication) as taken",
                "Log \(\.$medication)"
            ],
            shortTitle: "Mark Medication",
            systemImageName: "pills"
        )
    }
}
```

## Important Build Notes

- Use SwiftUI for the app interface.
- Use SwiftData or Core Data for medication and log storage.
- Use UserNotifications for reminders.
- Use App Intents for Siri and Shortcuts.
- Start with iOS 17 or newer.
- Avoid medical advice language. The app should track and remind, not diagnose or recommend treatment.
