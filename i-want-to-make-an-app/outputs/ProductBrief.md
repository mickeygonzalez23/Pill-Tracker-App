# Medication Siri App Product Brief

## App Name

Did I Take It? Pill Tracker

## Product Summary

Did I Take It? Pill Tracker is an iPhone medication tracking app that lets users mark medication as taken manually or by speaking to Siri. The unique feature is a Siri-safe nickname for each medication, so the user can log doses while the iPhone is locked without Siri saying sensitive medication names aloud.

## Target User

People who take one or more medications and want a quick, private way to confirm doses throughout the day.

## Main Problem

Medication tracker apps often require opening the app, tapping through screens, or exposing real medication names in notifications and voice responses. This can be inconvenient or uncomfortable, especially around other people.

## Main Solution

Let users assign private nicknames such as "morning pill," "sugar pill," or "night pill." Siri can use those nicknames to mark medications as taken, even while the phone is locked.

## Core User Flow

1. User adds a medication.
2. User enters the real medication name, dose, and schedule.
3. User assigns a Siri-safe nickname.
4. The app shows due medications on the Today screen.
5. User says, "Hey Siri, I took my sugar pill."
6. The app marks that medication as taken.
7. Siri replies, "Marked sugar pill as taken."
8. User can review or undo the log inside the app.

## MVP Features

- Add medication.
- Edit medication.
- Delete medication.
- Add Siri-safe nickname.
- Prevent duplicate nicknames.
- Set frequency.
- Set one or more dose times.
- Mark medication as taken manually.
- Mark medication as taken through Siri.
- Mark all due medications as taken.
- Show daily status.
- Show history.
- Undo recent logs.
- Support locked-phone Siri logging with nicknames.

## Deferred Features

- Apple Health integration.
- Caregiver sharing.
- Refill tracking.
- Barcode scanning.
- Multiple users.
- Doctor or pharmacy export.
- Complex medication schedules.
- Watch app.

## Privacy Behavior

- Real medication names stay inside the app.
- Siri and locked-screen interactions use nicknames.
- Notifications should use nicknames by default.
- The app should offer a setting to hide real medication names from widgets and notifications.
- If a Siri command is ambiguous, the app should ask the user to open the app rather than read medication names aloud.

## Siri Command Examples

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

## Locked Phone Siri Rules

The locked-phone intent should be allowed only for simple logging actions.

Allowed while locked:

- Mark nickname as taken.
- Mark a specific dose number as taken.
- Mark a specific dose time as taken.
- Mark next due medication as taken.
- Mark all currently due medications as taken.
- Check whether today's medications are marked as taken.
- Check whether a specific nickname is marked as taken today.

Not allowed while locked:

- Show real medication names.
- Read dose details aloud.
- List full medication history.
- Edit medications.
- Delete logs.
- Change reminders.

## Suggested App Screens

### Today

Purpose: quick daily medication status.

Elements:

- Greeting and date.
- List of doses due today.
- Status for each item.
- "Mark Taken" action.
- "Undo" action after logging.
- Siri status check for today's medications.

### Medications

Purpose: manage medication list.

Elements:

- Medication list.
- Real name.
- Siri nickname.
- Time.
- Reminder status.
- Add medication button.

### Medication Detail

Purpose: add or edit one medication.

Elements:

- Real medication name.
- Dose.
- Siri nickname.
- Schedule.
- Reminder toggle.
- Privacy note explaining Siri-safe names.

### History

Purpose: review what was logged.

Elements:

- Date grouped logs.
- Time taken.
- Nickname.
- Real name visible only in the app.
- Undo option.

### Siri Setup

Purpose: explain and test voice commands.

Elements:

- List of supported phrases.
- Nickname quality checks.
- Locked-phone behavior summary.
- Test phrase preview.

## Data Model

### Medication

```text
id
realName
dose
siriNickname
frequency
doseTimes
reminderEnabled
createdAt
updatedAt
isArchived
```

### MedicationLog

```text
id
medicationId
doseNumber
doseTime
takenAt
source
status
createdAt
```

## Multiple Daily Doses

If the same medication is taken more than once per day, the app should track each dose separately.

Example:

```text
Sugar pill dose 1 - Morning
Sugar pill dose 2 - Evening
```

The user can tell Siri:

```text
Hey Siri, I took sugar pill dose 1.
Hey Siri, I took sugar pill dose 2.
Hey Siri, I took my morning sugar pill.
Hey Siri, I took my evening sugar pill.
```

If the user says only:

```text
Hey Siri, I took my sugar pill.
```

The app should mark the next clearly due dose. If more than one dose could match, Siri should ask which dose was taken.

For custom times, each dose should have:

```text
Dose number
Exact time
Optional label
Reminder on/off
```

Example:

```text
Dose 1 - 8:00 AM - Breakfast
Dose 2 - 2:00 PM - Afternoon
Dose 3 - 9:00 PM - Bedtime
```

Allowed log sources:

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

## Technical Build Plan For MacBook

1. Create an iOS SwiftUI project in Xcode.
2. Use SwiftData for medication and log storage.
3. Build the Today, Medications, Detail, History, and Siri Setup screens.
4. Add App Intents for Siri and Shortcuts.
5. Configure the mark-taken intent to run while locked.
6. Add local notification reminders.
7. Test on a real iPhone.
8. Prepare app privacy wording for App Store submission.

## First Build Milestone

The first successful build should prove this:

```text
User creates "Metformin" with nickname "sugar pill."
User says, "Hey Siri, I took my sugar pill."
The app logs the dose.
Siri says, "Marked sugar pill as taken."
The Today screen shows that the dose was taken.
```
