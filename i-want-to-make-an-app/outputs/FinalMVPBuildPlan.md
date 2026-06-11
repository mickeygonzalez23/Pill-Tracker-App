# Did I Take It? Pill Tracker Final MVP Build Plan

## Approved App Direction

Did I Take It? Pill Tracker is an iPhone app that helps users track whether they took their pills. The key feature is private Siri logging using user-created pill nicknames, dose numbers, and dose labels.

## Version 1 Goal

Build a simple, reliable iPhone app that lets the user:

```text
Add pills
Assign Siri-safe nicknames
Set frequency and dose times
Mark doses as taken manually
Mark doses as taken with Siri
Ask Siri whether pills were taken today
Review weekly history
Edit or delete medications
```

## Version 1 Screens

### Today

Shows today's dose-level checklist.

Each row should show:

```text
Siri nickname
Dose number if needed
Real medication name
Dose amount
Dose time or custom label
Status
Mark Taken button
Siri phrase preview
```

Example:

```text
sugar pill dose 1
Metformin - 500 mg - Morning
Due
```

```text
sugar pill dose 2
Metformin - 500 mg - Evening
Next
```

### Meds

Shows all saved medications.

Each row should show:

```text
Real medication name
Siri nickname
Dose amount
Frequency
Dose times
Edit
Delete
```

### Add/Edit Medication

Fields:

```text
Real medication name
Dose
Siri nickname
Frequency
Dose times
Reminder setting
```

Frequency options:

```text
Once daily
Twice daily
Custom times
```

Preset dose times:

```text
Morning
Noon
Evening
Bedtime
```

Custom dose rows:

```text
Dose number
Exact time
Optional label
Reminder on/off
```

Example:

```text
Dose 1 - 8:00 AM - Breakfast
Dose 2 - 8:00 PM - Bedtime
```

### History

Shows a weekly calendar.

Behavior:

```text
Tap a day
See pills/doses marked taken that day
Undo mistaken logs
```

### Siri

Shows supported Siri phrases and explains privacy.

## Version 1 Siri Commands

### Mark Taken

```text
Hey Siri, I took my medication.
Hey Siri, I took my meds.
Hey Siri, I took all of my medication.
Hey Siri, I took all of my meds.
Hey Siri, I took my sugar pill.
Hey Siri, mark sugar pill as taken.
```

### Mark Specific Dose

```text
Hey Siri, I took sugar pill dose 1.
Hey Siri, I took sugar pill dose 2.
Hey Siri, I took my morning sugar pill.
Hey Siri, I took my evening sugar pill.
Hey Siri, I took my breakfast sugar pill.
Hey Siri, I took my bedtime sugar pill.
```

### Check Status

```text
Hey Siri, did I take my pills today?
Hey Siri, did I take my meds today?
Hey Siri, did I take my medication today?
Hey Siri, did I take my sugar pill today?
```

## Siri Response Rules

Siri should use privacy-safe wording.

Good:

```text
Marked sugar pill dose 1 as taken.
Marked evening sugar pill as taken.
You marked 2 of 3 pills as taken today.
All of your pills are marked as taken today.
```

Avoid:

```text
Marked Metformin 500 mg as taken.
You still need to take Lisinopril.
```

## Locked iPhone Behavior

Allowed while locked:

```text
Mark one nickname as taken
Mark one dose number as taken
Mark one dose label/time as taken
Mark all due pills as taken
Ask whether pills were taken today
Ask whether a nickname was taken today
```

Not allowed while locked:

```text
Read real medication names
Read dose amounts
Edit medications
Delete medications
Show full history
Change reminders
```

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
isArchived
createdAt
updatedAt
```

### Dose Time

```text
id
medicationId
doseNumber
label
time
reminderEnabled
```

### Medication Log

```text
id
medicationId
doseTimeId
doseNumber
doseLabel
medicationNickname
takenAt
source
status
createdAt
```

Log sources:

```text
manual
siriUnlocked
siriLocked
notification
```

Log statuses:

```text
taken
skipped
missed
undone
```

## Validation Rules

```text
Real medication name is required.
Dose is optional but recommended.
Siri nickname is required.
Siri nickname must be unique.
At least one dose time is required.
Custom dose labels are optional.
Duplicate custom labels should be warned against.
```

## Version 1 Includes

```text
Local iPhone storage
No account required
Manual dose logging
Siri dose logging
Siri status checks
Siri-safe nicknames
Dose numbers
Custom dose labels
Weekly history calendar
Edit medication
Delete medication
Undo log
Local reminders
Locked-phone Siri support where iOS allows it
```

## Save For Later

```text
Apple Watch app
Caregiver sharing
Cloud sync
Medication refill tracking
Pharmacy integration
Barcode scanning
Doctor export
Apple Health integration
Multiple user profiles
Advanced recurring schedules
Photos of pills
```

## MacBook Build Roadmap

### Step 1

Install Xcode and create the iOS SwiftUI project.

Recommended settings:

```text
Product Name: Did I Take It? Pill Tracker
Interface: SwiftUI
Language: Swift
Storage: SwiftData
Minimum iOS: iOS 17+
```

### Step 2

Build the SwiftData models:

```text
Medication
DoseTime
MedicationLog
```

### Step 3

Build the app screens:

```text
Today
Meds
Add/Edit Medication
History
Siri
```

### Step 4

Add local manual logging:

```text
Mark Taken
Undo
Weekly history
```

### Step 5

Add reminders using UserNotifications.

### Step 6

Add App Intents:

```text
MarkMedicationTakenIntent
MarkMedicationDoseTakenIntent
MarkMedicationDoseTimeTakenIntent
MarkAllDueMedicationsTakenIntent
CheckTodayMedicationStatusIntent
CheckMedicationNicknameStatusIntent
```

### Step 7

Test on a real iPhone:

```text
Unlocked Siri logging
Locked Siri logging
Specific dose number
Specific dose label
Ask status today
Multiple pills due
Duplicate nickname prevention
Undo
Delete
Edit
```

### Step 8

Prepare App Store materials:

```text
Privacy policy
App description
Screenshots
Medical disclaimer
Apple Developer Program account
```

## First Success Test

The first real app milestone is:

```text
Create medication: Metformin
Dose: 500 mg
Nickname: sugar pill
Frequency: Twice daily
Dose 1: Morning
Dose 2: Evening

Say: Hey Siri, I took sugar pill dose 1.
Result: Only dose 1 is marked taken.

Say: Hey Siri, did I take my pills today?
Result: Siri says how many doses are marked taken today.
```

