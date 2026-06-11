# Did I Take It? Pill Tracker Privacy And App Store Checklist

## Important Positioning

Did I Take It? Pill Tracker should be described as a medication tracking and reminder app, not a medical advice app.

Use wording like:

```text
Track when you take your medications.
Set reminders.
Use Siri-safe nicknames for private logging.
Review your medication history.
```

Avoid wording like:

```text
Improves your health.
Prevents missed medication.
Keeps you safe.
Recommends what medication to take.
Diagnoses medication problems.
```

## Privacy Policy Topics

The privacy policy should explain:

- What medication information the user enters.
- Where the data is stored.
- Whether data leaves the device.
- Whether analytics are used.
- Whether crash reporting is used.
- Whether notifications use nicknames or real medication names.
- How the user can delete their data.

## Recommended MVP Privacy Approach

For the first version:

```text
Store data locally on the user's iPhone.
Do not require an account.
Do not sell or share data.
Do not use advertising.
Use nicknames for Siri and notifications by default.
```

## App Store Review Notes

Before submitting:

- Join the Apple Developer Program.
- Add a privacy policy URL.
- Fill out Apple's app privacy questionnaire.
- Avoid claims that the app provides medical treatment.
- Make clear that users should follow clinician instructions.
- Test the app with VoiceOver.
- Test larger text sizes.
- Test Siri commands on a real iPhone.
- Test locked-phone behavior.

## Suggested In-App Disclaimer

```text
Did I Take It? Pill Tracker helps you record and remember medications. It does not provide medical advice. Always follow instructions from your healthcare professional.
```

## Notification Privacy Setting

The app should include a setting:

```text
Use Siri nicknames in reminders
```

Default:

```text
On
```

Example private notification:

```text
Time to take your morning pill.
```

Example less private notification:

```text
Time to take Metformin.
```

## Locked Siri Privacy

While locked, Siri should not:

- Speak real medication names.
- Speak doses.
- List medication history.
- Ask the user to choose from real medication names.

While locked, Siri can:

- Confirm a nickname was marked as taken.
- Confirm all due meds were marked as taken.
- Say no medications are due.
