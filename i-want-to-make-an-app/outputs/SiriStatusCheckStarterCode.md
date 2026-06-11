# Did I Take It? Pill Tracker Siri Status Check Starter Code

This adds the Siri behavior for questions like:

```text
Hey Siri, did I take my pills today?
Hey Siri, did I take my meds today?
Hey Siri, did I take my sugar pill today?
```

## CheckTodayMedicationStatusIntent.swift

```swift
import AppIntents
import Foundation

struct CheckTodayMedicationStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Today's Medication Status"
    static var description = IntentDescription("Checks whether today's medications are marked as taken.")
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        let status = try await MedicationIntentStore.shared.todayStatus()

        if status.totalDue == 0 {
            return .result(dialog: "You do not have any pills due today.")
        }

        if status.takenCount == status.totalDue {
            return .result(dialog: "All of your pills are marked as taken today.")
        }

        if status.takenCount == 0 {
            return .result(dialog: "No pills are marked as taken today.")
        }

        return .result(
            dialog: "You marked \(status.takenCount) of \(status.totalDue) pills as taken today."
        )
    }
}
```

## CheckMedicationNicknameStatusIntent.swift

```swift
import AppIntents
import Foundation

struct CheckMedicationNicknameStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Medication Status"
    static var description = IntentDescription("Checks whether a medication nickname is marked as taken today.")
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Medication")
    var medication: MedicationEntity

    func perform() async throws -> some IntentResult {
        let isTaken = try await MedicationIntentStore.shared.isTakenToday(
            medicationID: medication.id
        )

        if isTaken {
            return .result(dialog: "\(medication.siriNickname) is marked as taken today.")
        }

        return .result(dialog: "\(medication.siriNickname) is not marked as taken today.")
    }
}
```

## TodayMedicationStatus.swift

```swift
import Foundation

struct TodayMedicationStatus {
    let totalDue: Int
    let takenCount: Int
}
```

## MedicationShortcuts Additions

Add these shortcuts to the existing `MedicationShortcuts` provider.

```swift
AppShortcut(
    intent: CheckTodayMedicationStatusIntent(),
    phrases: [
        "Did I take my pills today in \(.applicationName)",
        "Did I take my meds today in \(.applicationName)",
        "Did I take my medication today in \(.applicationName)"
    ],
    shortTitle: "Check Pills",
    systemImageName: "questionmark.circle"
)

AppShortcut(
    intent: CheckMedicationNicknameStatusIntent(),
    phrases: [
        "Did I take \(\.$medication) today in \(.applicationName)",
        "Did I take my \(\.$medication) today in \(.applicationName)",
        "Check \(\.$medication) today in \(.applicationName)"
    ],
    shortTitle: "Check Medication",
    systemImageName: "checklist"
)
```

## MedicationIntentStore Additions

Add these methods to `MedicationIntentStore`.

```swift
func todayStatus() async throws -> TodayMedicationStatus {
    // Count medications due today and logs marked taken today.
    TodayMedicationStatus(totalDue: 0, takenCount: 0)
}

func isTakenToday(medicationID: String) async throws -> Bool {
    // Return true if this medication has a taken log for today.
    false
}
```

## Privacy Rule

Siri status responses should use generic words like "pills" or user-created nicknames. Siri should not say real medication names or dose details while the iPhone is locked.

