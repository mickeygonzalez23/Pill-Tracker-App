# Did I Take It? Pill Tracker Frequency And Dose Times Starter Code

Use this structure so one medication can have more than one dose time per day.

Example:

```text
Medication: Metformin
Dose: 500 mg
Frequency: Twice daily
Dose times: Morning, Evening
Nickname: sugar pill
```

## DoseFrequency.swift

```swift
import Foundation

enum DoseFrequency: String, Codable, CaseIterable, Identifiable {
    case onceDaily
    case twiceDaily
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .onceDaily:
            "Once daily"
        case .twiceDaily:
            "Twice daily"
        case .custom:
            "Custom times"
        }
    }
}
```

## DoseTime.swift

```swift
import Foundation

enum DoseTime: String, Codable, CaseIterable, Identifiable {
    case morning
    case noon
    case evening
    case bedtime

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .morning:
            "Morning"
        case .noon:
            "Noon"
        case .evening:
            "Evening"
        case .bedtime:
            "Bedtime"
        }
    }
}
```

## Medication Model Change

Replace the single `scheduledTime` field with:

```swift
var frequency: DoseFrequency
var doseTimes: [DoseTime]
```

The medication model initializer should require at least one dose time:

```swift
init(
    realName: String,
    dose: String,
    siriNickname: String,
    frequency: DoseFrequency,
    doseTimes: [DoseTime],
    reminderEnabled: Bool = true
) {
    precondition(!doseTimes.isEmpty, "A medication must have at least one dose time.")

    self.realName = realName
    self.dose = dose
    self.siriNickname = siriNickname
    self.frequency = frequency
    self.doseTimes = doseTimes
    self.reminderEnabled = reminderEnabled
    self.isArchived = false
    self.createdAt = Date()
    self.updatedAt = Date()
}
```

## UI Behavior

When the user selects:

```text
Once daily
```

Default dose time:

```text
Morning
```

When the user selects:

```text
Twice daily
```

Default dose times:

```text
Morning
Evening
```

When the user selects:

```text
Custom times
```

Let the user choose one or more:

```text
Morning
Noon
Evening
Bedtime
```

For the full version of custom times, use editable dose rows instead of only preset labels:

```text
Dose 1
time: 08:00
label: Breakfast
reminderEnabled: true

Dose 2
time: 20:00
label: Bedtime
reminderEnabled: true
```

Suggested model:

```swift
struct CustomDoseTime: Codable, Identifiable {
    var id: UUID
    var time: Date
    var label: String
    var reminderEnabled: Bool
}
```
