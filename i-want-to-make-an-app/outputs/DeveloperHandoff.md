# Did I Take It? Pill Tracker Developer Handoff

## Project Summary

Did I Take It? Pill Tracker is an iPhone medication tracker focused on fast, private logging. Users can mark medications as taken in the app or through Siri. The app's key privacy feature is a user-created Siri nickname for each medication, so Siri can confirm a dose while the iPhone is locked without saying the real medication name aloud.

## Core MVP

The first version should prove this flow:

```text
User adds medication: Metformin
User assigns Siri nickname: sugar pill
User says: Hey Siri, I took my sugar pill.
App marks Metformin as taken.
Siri says: Marked sugar pill as taken.
```

## Target Platform

```text
iPhone
iOS 17 or newer
SwiftUI
SwiftData
App Intents
UserNotifications
```

## Primary Screens

```text
Today
Meds
Add/Edit Medication
History
Siri Setup
```

## Required User Stories

```text
As a user, I can add a medication.
As a user, I can delete a medication.
As a user, I can add a Siri-safe nickname.
As a user, I can set a frequency.
As a user, I can set one or more dose times.
As a user, I can see medications due today.
As a user, I can manually mark a medication as taken.
As a user, I can ask Siri to mark a nickname as taken.
As a user, I can ask Siri to mark a specific dose number as taken.
As a user, I can ask Siri to mark a specific dose time as taken.
As a user, I can ask Siri to mark all due meds as taken.
As a user, I can ask Siri whether I took my pills today.
As a user, I can ask Siri whether I took a specific nickname today.
As a user, I can review medication history.
As a user, I can undo a mistaken log.
```

## Privacy Requirements

- Siri responses should use nicknames only.
- Real medication names should stay inside the app.
- Locked-phone Siri actions should not reveal dose details.
- Notifications should use nicknames by default.
- Duplicate nicknames must be blocked.
- Ambiguous Siri matches should ask the user to open the app.

## Siri Commands

The app should support phrases similar to:

```text
Hey Siri, I took my medication.
Hey Siri, I took my meds.
Hey Siri, I took all of my medication.
Hey Siri, I took all of my meds.
Hey Siri, I took my sugar pill.
Hey Siri, I took sugar pill dose 1.
Hey Siri, I took sugar pill dose 2.
Hey Siri, I took my morning sugar pill.
Hey Siri, I took my evening sugar pill.
Hey Siri, mark sugar pill as taken.
Hey Siri, log my morning pill.
Hey Siri, I took my night pill.
Hey Siri, mark all due meds as taken.
Hey Siri, did I take my pills today?
Hey Siri, did I take my meds today?
Hey Siri, did I take my sugar pill today?
```

## Locked Phone Behavior

Allowed while locked:

```text
Mark one nickname as taken
Mark next due medication as taken
Mark all due medications as taken
Check today's medication status
Check whether one nickname was taken today
```

Not allowed while locked:

```text
Read real medication names aloud
Read dose details aloud
Edit medications
Delete medications
Show full history
Change reminders
```

## Data Models

### Medication

```text
id
realName
dose
siriNickname
frequency
doseTimes
reminderEnabled
isArchived
createdAt
updatedAt
```

### MedicationLog

```text
id
medicationId
doseNumber
doseTime
medicationNickname
takenAt
source
status
createdAt
```

Allowed sources:

```text
manual
siriUnlocked
siriLocked
notification
```

Allowed statuses:

```text
taken
skipped
missed
undone
```

## Acceptance Tests

### Manual Logging

```text
Given a medication is due today
When the user taps Mark Taken
Then the medication appears as Taken on Today
And a log appears in History
```

### Siri Nickname Logging

```text
Given a medication exists with nickname sugar pill
When the user says "Hey Siri, I took my sugar pill"
Then the app creates a taken log
And Siri says "Marked sugar pill as taken"
```

### Siri Dose Number Logging

```text
Given a medication exists with nickname sugar pill
And it has dose 1 and dose 2 today
When the user says "Hey Siri, I took sugar pill dose 2"
Then the app marks only dose 2 as taken
And dose 1 is unchanged
```

### Duplicate Nicknames

```text
Given one medication already uses morning pill
When the user tries to save another medication with morning pill
Then the app blocks the save
And says the nickname is already used
```

### Locked Phone Privacy

```text
Given the iPhone is locked
When Siri marks a medication as taken
Then Siri speaks only the nickname
And does not speak the real medication name or dose
```

### Siri Status Check

```text
Given the user has 3 medications due today
And 2 are marked taken
When the user says "Hey Siri, did I take my pills today?"
Then Siri says "You marked 2 of 3 pills as taken today"
And Siri does not say real medication names
```

### Undo

```text
Given a medication was marked as taken by mistake
When the user taps Undo
Then the log is marked undone
And Today no longer shows the dose as taken
```

## Current Windows Prep Files

```text
ProductBrief.md
ScreenSpec.md
MacBookBuildChecklist.md
SwiftStarterCode.md
MedicationSiriMVP.md
DidITakeItPillTrackerPrototype.html
```

Note: the prototype file is named DidITakeItPillTrackerPrototype.html.
