//
//  Pill_TrackerApp.swift
//  Pill Tracker
//
//  Created by Jose Gonzalez on 6/11/26.
//

import SwiftUI

@main
struct Pill_TrackerApp: App {
    @UIApplicationDelegateAdaptor(NotificationResponseHandler.self) private var notificationResponseHandler

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
