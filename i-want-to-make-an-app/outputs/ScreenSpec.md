# Did I Take It? Pill Tracker Screen Spec

## Navigation

The first version should use four tabs:

```text
Today
Meds
History
Siri
```

## Today Tab

Purpose: help the user quickly see what is due and mark medication as taken.

### Shows

- Current date.
- Count of medications taken today.
- Count of medications still due.
- List of today's medications.

### Each Medication Row Shows

- Siri nickname as the main label.
- Real medication name as secondary text.
- Dose.
- Time of day.
- Dose number when a medication has multiple daily doses.
- Status: Due, Taken, Next, Missed.

### Actions

- Mark Taken.
- Undo after marking.
- Show Siri phrase preview.

### Empty State

If nothing is due:

```text
No medications due right now.
```

## Meds Tab

Purpose: manage saved medications.

### Shows

- List of active medications.
- Add medication button.

### Each Medication Row Shows

- Real medication name.
- Siri nickname.
- Dose.
- Schedule.
- Reminder on/off status.

### Actions

- Add medication.
- Edit medication.
- Delete medication.
- Archive medication later if needed.

### Edit Behavior

When the user taps Edit:

```text
Open the medication form.
Fill in the current real name, dose, nickname, frequency, and dose times.
Change the button from Save Medication to Update Medication.
Save the edited values back to the same medication.
```

### Delete Behavior

When the user deletes a medication:

```text
Remove it from the Meds list.
Remove future due doses from Today.
Keep or remove history depending on final privacy decision.
```

For the MVP prototype, deleting a medication also removes its visible history logs.

## Add/Edit Medication Screen

Purpose: create or update a medication and its Siri-safe nickname.

### Fields

```text
Real medication name
Dose
Siri nickname
Frequency
Dose times
Reminder enabled
```

### Validation

- Real medication name is required.
- Siri nickname is required.
- Siri nickname must be unique.
- Siri nickname should be easy to say.
- Extra spaces should be cleaned up.
- Nickname matching should ignore uppercase/lowercase.
- At least one dose time is required.

### Frequency Options

```text
Once daily
Twice daily
Custom times
```

### Dose Time Options

```text
Morning
Noon
Evening
Bedtime
```

When the user selects Custom times, show editable custom dose rows:

```text
Dose 1
Time
Label
Reminder on/off

Dose 2
Time
Label
Reminder on/off

+ Add Dose
```

Custom dose labels can be used by Siri:

```text
Hey Siri, I took my breakfast sugar pill.
Hey Siri, I took my bedtime sugar pill.
```

Example:

```text
Real medication name: Metformin
Dose: 500 mg
Frequency: Twice daily
Dose times: Morning, Evening
Siri nickname: sugar pill
```

### Privacy Helper Text

```text
Siri uses this nickname instead of the real medication name, including while your iPhone is locked.
```

### Example Nicknames

```text
morning pill
sugar pill
night pill
blood pressure pill
vitamin
```

## History Tab

Purpose: let the user review what was taken by week and undo mistakes.

### Shows

- Weekly calendar row.
- Clickable day buttons.
- Dots on days with medication logs.
- Selected day summary.
- Siri nickname.
- Real medication name.
- Time marked taken.
- Source: manual, Siri, notification.

### Actions

- Select a day.
- Undo recent log.
- Filter by medication later, not needed in MVP.

### Empty State

```text
No pills were marked taken on this day.
```

## Siri Tab

Purpose: explain Siri setup and show the user what to say.

### Shows

- List of supported phrases.
- Reminder that Siri uses nicknames.
- Locked-phone privacy explanation.
- Status-check examples for asking whether pills were taken.
- Nickname quality warnings if needed.

### Supported Phrase Examples

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
Hey Siri, did I take my pills today?
Hey Siri, did I take my meds today?
Hey Siri, did I take my sugar pill today?
```

### Locked Phone Explanation

```text
When your iPhone is locked, Siri can mark medication as taken using your nickname. Siri will not say the real medication name out loud.
```

### Siri Status Responses

For all pills:

```text
You marked 2 of 3 pills as taken today.
```

For a specific nickname:

```text
Sugar pill is marked as taken today.
```

### Multiple Daily Dose Siri Rules

If a medication has more than one dose today, the user can specify the dose by number or by time:

```text
Hey Siri, I took sugar pill dose 1.
Hey Siri, I took sugar pill dose 2.
Hey Siri, I took my morning sugar pill.
Hey Siri, I took my evening sugar pill.
```

If the user only says:

```text
Hey Siri, I took my sugar pill.
```

The app should mark the next clearly due dose. If there are multiple possible matches, Siri should ask which dose was taken.

## Important Edge Cases

### Duplicate Nickname

If the user tries to save two medications with the same nickname:

```text
That Siri nickname is already used. Choose a different nickname.
```

### Unknown Siri Nickname

If Siri cannot match the nickname:

```text
I could not find that medication nickname.
```

### Multiple Possible Matches

If the app cannot safely decide:

```text
I found more than one match. Please open the app to choose.
```

### Already Taken

If the user tries to mark the same medication again:

```text
This was already marked as taken today.
```

The app can offer:

```text
Log another dose
Cancel
```

## MVP Design Direction

- Clear and calm.
- Large touch targets.
- High contrast.
- No clutter.
- Nicknames should be prominent.
- Real medication names should be visible inside the app, but not emphasized in Siri responses.
