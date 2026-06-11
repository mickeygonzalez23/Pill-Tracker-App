# Med Fed Pill Tracker MacBook Build Checklist

## What You Need

- MacBook or Mac mini
- Xcode installed from the Mac App Store
- iPhone for testing Siri
- Apple ID
- Apple Developer Program membership only when you are ready to publish

## Recommended Xcode Project Settings

```text
Product Name: Med Fed Pill Tracker
Interface: SwiftUI
Language: Swift
Storage: SwiftData
Minimum iOS: iOS 17
```

## First Build Goal

Create the smallest real iPhone app that proves the core idea:

```text
Add medication: Metformin
Add Siri nickname: sugar pill
Say: Hey Siri, I took my sugar pill.
Result: The app marks it as taken.
Siri says: Marked sugar pill as taken.
```

## Build Order

### 1. Create Project

- Open Xcode.
- Create a new iOS App.
- Name it Med Fed Pill Tracker.
- Select SwiftUI.
- Select SwiftData if Xcode offers the option.

### 2. Add Data Models

Create models for:

- Medication
- MedicationLog

Medication fields:

```text
realName
dose
siriNickname
scheduledTime
reminderEnabled
isArchived
```

MedicationLog fields:

```text
medication
takenAt
source
status
```

### 3. Build Basic Screens

Build these screens first:

- Today
- Medications
- Medication Detail
- History
- Siri Setup

### 4. Add Manual Logging

The app should let the user tap:

```text
Mark Taken
```

Then the app should:

- Create a MedicationLog.
- Update Today status.
- Add the log to History.
- Allow Undo.

### 5. Add Nickname Rules

Before saving a medication:

- Require a Siri nickname.
- Trim extra spaces.
- Make nickname matching case-insensitive.
- Prevent duplicate nicknames.
- Keep real medication names inside the app UI.

### 6. Add Siri App Intent

Add an App Intent named:

```text
MarkMedicationTakenIntent
```

The intent should:

- Accept a medication entity.
- Match using the Siri nickname.
- Mark the medication as taken.
- Reply with the nickname only.
- Avoid opening the app.

### 7. Allow Locked iPhone Logging

Set the intent authentication policy:

```swift
static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
```

Locked-phone Siri should allow:

- Mark nickname as taken.
- Mark next due medication as taken.
- Mark all due medications as taken.

Locked-phone Siri should not allow:

- Reading real medication names.
- Reading dose details.
- Editing medications.
- Deleting logs.
- Showing medication history.

### 8. Add Notifications

Use local notifications for reminders.

Notification wording should default to nicknames:

```text
Time to take your morning pill.
```

### 9. Test On iPhone

Test:

- Manual marking.
- Siri while unlocked.
- Siri while locked.
- Duplicate nicknames.
- Similar nicknames.
- Missing nickname.
- All-due medication command.
- Undo.
- App restart.

### 10. Prepare For App Store

Before publishing:

- Join Apple Developer Program.
- Add privacy policy.
- Avoid medical advice claims.
- Explain data storage.
- Test accessibility text sizes.
- Test with VoiceOver.

## Good First Test Data

```text
Real name: Metformin
Dose: 500 mg
Nickname: sugar pill
Schedule: Morning
```

```text
Real name: Lisinopril
Dose: 10 mg
Nickname: morning pill
Schedule: Morning
```

```text
Real name: Atorvastatin
Dose: 20 mg
Nickname: night pill
Schedule: Evening
```

