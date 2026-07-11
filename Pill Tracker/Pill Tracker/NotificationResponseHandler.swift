//
//  NotificationResponseHandler.swift
//  Pill Tracker
//
//  Created by Jose Gonzalez on 6/12/26.
//

import UIKit
import UserNotifications

final class NotificationResponseHandler: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        NotificationScheduler.registerCategories()
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo

        guard
            let medicationID = userInfo["medicationID"] as? String,
            let doseTime = userInfo["doseTime"] as? String
        else {
            return
        }

        switch response.actionIdentifier {
        case NotificationScheduler.takenActionIdentifier:
            MedicationIntentStore.markMedicationDose(id: medicationID, doseTime: doseTime, as: .taken)
        case NotificationScheduler.unsureActionIdentifier:
            MedicationIntentStore.markMedicationDose(id: medicationID, doseTime: doseTime, as: .unsure)
        case NotificationScheduler.skippedActionIdentifier:
            MedicationIntentStore.markMedicationDose(id: medicationID, doseTime: doseTime, as: .skipped)
        case NotificationScheduler.snoozeActionIdentifier:
            guard let medication = MedicationIntentStore.medication(id: medicationID) else {
                return
            }

            NotificationScheduler.scheduleSnooze(
                medicationName: medication.siriNickname,
                dose: medication.dose,
                medicationID: medicationID,
                doseTime: doseTime
            )
        default:
            return
        }
    }
}
