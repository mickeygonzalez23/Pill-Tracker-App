//
//  NotificationScheduler.swift
//  Pill Tracker
//
//  Created by Jose Gonzalez on 6/12/26.
//

import Foundation
import UserNotifications

enum NotificationScheduler {
    static let reminderCategoryIdentifier = "MEDICATION_REMINDER"
    static let takenActionIdentifier = "MARK_TAKEN"
    static let unsureActionIdentifier = "MARK_UNSURE"
    static let snoozeActionIdentifier = "REMIND_LATER"

    private static let reminderPrefix = "medication-reminder-"
    private static let snoozePrefix = "medication-snooze-"

    static func registerCategories() {
        let takenAction = UNNotificationAction(
            identifier: takenActionIdentifier,
            title: "Taken",
            options: []
        )
        let unsureAction = UNNotificationAction(
            identifier: unsureActionIdentifier,
            title: "Not Sure",
            options: []
        )
        let snoozeAction = UNNotificationAction(
            identifier: snoozeActionIdentifier,
            title: "Remind Me Later",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: reminderCategoryIdentifier,
            actions: [takenAction, unsureAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    static func requestPermissionAndSchedule(for medications: [Medication]) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else {
                return
            }

            scheduleReminders(for: medications)
        }
    }

    static func scheduleReminders(for medications: [Medication]) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                return
            }

            replaceMedicationReminders(with: medications)
        }
    }

    private static func replaceMedicationReminders(with medications: [Medication]) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let existingReminderIDs = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(reminderPrefix) }

            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: existingReminderIDs)

            medications.filter(\.remindersEnabled).forEach { medication in
                scheduleMedication(medication)
            }
        }
    }

    private static func scheduleMedication(_ medication: Medication) {
        let weekdays = medication.dayScheduleKind == .everyDay
            ? Weekday.allCases.map(\.id)
            : medication.selectedWeekdays

        weekdays.forEach { weekday in
            medication.displayDoseTimes.forEach { doseTime in
                guard let time = parseDoseTime(doseTime) else {
                    return
                }

                let content = UNMutableNotificationContent()
                content.title = "Pill Reminder"
                content.body = "Time for \(medication.siriNickname) (\(medication.dose))."
                content.sound = .default
                content.categoryIdentifier = reminderCategoryIdentifier
                content.userInfo = [
                    "medicationID": medication.id.uuidString,
                    "doseTime": doseTime
                ]

                var components = DateComponents()
                components.weekday = weekday
                components.hour = time.hour
                components.minute = time.minute

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let identifier = "\(reminderPrefix)\(medication.id.uuidString)-\(weekday)-\(doseTime)"
                    .replacingOccurrences(of: " ", with: "-")
                    .replacingOccurrences(of: ":", with: "")
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request)
            }
        }
    }

    private static func parseDoseTime(_ doseTime: String) -> (hour: Int, minute: Int)? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"

        guard let date = formatter.date(from: doseTime) else {
            return nil
        }

        let components = Calendar.current.dateComponents([.hour, .minute], from: date)

        guard let hour = components.hour, let minute = components.minute else {
            return nil
        }

        return (hour, minute)
    }

    static func scheduleSnooze(medicationName: String, dose: String, medicationID: String, doseTime: String) {
        let content = UNMutableNotificationContent()
        content.title = "Pill Reminder"
        content.body = "Checking back: \(medicationName) (\(dose))."
        content.sound = .default
        content.categoryIdentifier = reminderCategoryIdentifier
        content.userInfo = [
            "medicationID": medicationID,
            "doseTime": doseTime
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10 * 60, repeats: false)
        let identifier = "\(snoozePrefix)\(medicationID)-\(doseTime)-\(Date().timeIntervalSince1970)"
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: ":", with: "")
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
