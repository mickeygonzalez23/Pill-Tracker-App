//
//  ContentView.swift
//  Pill Tracker
//
//  Created by Jose Gonzalez on 6/11/26.
//

import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.12, green: 0.58, blue: 0.72)
    static let softAccent = Color(red: 0.82, green: 0.95, blue: 0.98)
    static let pageBackground = Color(red: 0.91, green: 0.97, blue: 0.99)
}

enum DoseStatus: String, Codable {
    case due = "Due"
    case taken = "Taken"
    case unsure = "Not Sure"
    case skipped = "Skipped"

    var color: Color {
        switch self {
        case .due:
            return .orange
        case .taken:
            return .green
        case .unsure:
            return Color(red: 0.43, green: 0.39, blue: 0.58)
        case .skipped:
            return .blue
        }
    }
}

enum DoseHistory {
    nonisolated static func dateKey(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    nonisolated static func displayDate(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide).month(.wide).day().year())
    }

    nonisolated static func displayUpdateTime(_ date: Date) -> String {
        date.formatted(.dateTime.hour().minute())
    }
}

extension Medication {
    nonisolated func intervalOccurrences() -> [Date] {
        guard scheduleKind == .everyXHours,
              let start = intervalStartDate,
              let finish = intervalFinishDate,
              finish >= start else { return [] }
        let step = TimeInterval(max(intervalHours, 1) * 3_600)
        var result: [Date] = []
        var occurrence = start
        while occurrence <= finish {
            result.append(occurrence)
            occurrence = occurrence.addingTimeInterval(step)
        }
        return result
    }

    nonisolated func doseTimes(on date: Date) -> [String] {
        guard scheduleKind == .everyXHours else {
            return isScheduledByDayRules(on: date) ? displayDoseTimes : []
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return intervalOccurrences()
            .filter { Calendar.current.isDate($0, inSameDayAs: date) }
            .map { formatter.string(from: $0) }
    }

    mutating func setDoseStatus(_ status: DoseStatus?, for doseTime: String, on date: Date = Date()) {
        let dateKey = DoseHistory.dateKey(for: date)
        var statuses = doseStatusHistory[dateKey] ?? [:]
        var updatedAt = doseStatusUpdatedAtHistory[dateKey] ?? [:]
        var log = doseStatusLogHistory[dateKey] ?? [:]

        takenDoseTimesToday.removeAll { $0 == doseTime }
        unsureDoseTimesToday.removeAll { $0 == doseTime }

        if let status, status != .due {
            if status == .taken { takenDoseTimesToday.append(doseTime) }
            if status == .unsure { unsureDoseTimesToday.append(doseTime) }
            statuses[doseTime] = status.rawValue
            updatedAt[doseTime] = Date()
            appendDoseLog(status.rawValue, doseTime: doseTime, to: &log)
        } else {
            statuses.removeValue(forKey: doseTime)
            updatedAt.removeValue(forKey: doseTime)
            appendDoseLog("Cleared", doseTime: doseTime, to: &log)
        }

        doseStatusHistory[dateKey] = statuses.isEmpty ? nil : statuses
        doseStatusUpdatedAtHistory[dateKey] = updatedAt.isEmpty ? nil : updatedAt
        doseStatusLogHistory[dateKey] = log.isEmpty ? nil : log
    }

    private func appendDoseLog(_ status: String, doseTime: String, to log: inout [String: [DoseStatusLogEntry]]) {
        var entries = log[doseTime] ?? []
        entries.append(DoseStatusLogEntry(status: status, changedAt: Date()))
        log[doseTime] = Array(entries.suffix(20))
    }

    nonisolated func isScheduled(on date: Date) -> Bool {
        if scheduleKind == .everyXHours {
            return !doseTimes(on: date).isEmpty
        }
        return isScheduledByDayRules(on: date)
    }

    private nonisolated func isScheduledByDayRules(on date: Date) -> Bool {
        let calendar = Calendar.current
        let selectedDay = calendar.startOfDay(for: date)
        let createdDay = calendar.startOfDay(for: createdAt)

        guard selectedDay >= createdDay else {
            return false
        }

        if dayScheduleKind == .everyDay {
            return true
        }

        let weekdayID = calendar.component(.weekday, from: date)
        return selectedWeekdays.contains(weekdayID)
    }

    nonisolated func doseStatus(for doseTime: String, on date: Date) -> DoseStatus {
        let key = DoseHistory.dateKey(for: date)

        if let rawStatus = doseStatusHistory[key]?[doseTime],
           let status = DoseStatus(rawValue: rawStatus) {
            return status
        }

        return .due
    }

    nonisolated func doseStatusUpdatedAt(for doseTime: String, on date: Date) -> Date? {
        let key = DoseHistory.dateKey(for: date)
        return doseStatusUpdatedAtHistory[key]?[doseTime]
    }

    nonisolated func doseStatusLog(for doseTime: String, on date: Date) -> [DoseStatusLogEntry] {
        let key = DoseHistory.dateKey(for: date)
        return doseStatusLogHistory[key]?[doseTime] ?? []
    }
}

struct ContentView: View {
    @StateObject private var store = MedicationStore()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isShowingAddMedication = false
    @State private var medicationToEdit: Medication?

    var body: some View {
        TabView {
            TodayView(
                medications: store.medications,
                isShowingAddMedication: $isShowingAddMedication,
                updateMedication: store.update
            )
            .tabItem {
                Label("Today", systemImage: "checklist")
            }

            MedicationsView(
                medications: store.medications,
                isShowingAddMedication: $isShowingAddMedication,
                medicationToEdit: $medicationToEdit,
                deleteMedication: store.delete
            )
            .tabItem {
                Label("Meds", systemImage: "pills")
            }

            HistoryView(medications: store.medications)
                .tabItem {
                    Label("History", systemImage: "calendar")
                }

            ShortcutsView(medications: store.medications)
                .tabItem {
                    Label("Shortcuts", systemImage: "waveform")
                }

            SettingsView(
                medicationCount: store.medications.count,
                resetAllData: store.resetAllData
            )
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .sheet(isPresented: $isShowingAddMedication) {
            MedicationFormView(
                title: "Add Medication",
                existingNicknames: store.medications.map(\.siriNickname),
                onSave: store.add
            )
        }
        .sheet(item: $medicationToEdit) { medication in
            MedicationFormView(
                title: "Edit Medication",
                medication: medication,
                existingNicknames: store.medications
                    .filter { $0.id != medication.id }
                    .map(\.siriNickname),
                onSave: store.update,
                onDelete: { medicationToDelete in
                    store.delete(medicationToDelete)
                    medicationToEdit = nil
                }
            )
        }
        .fullScreenCover(
            isPresented: Binding(
                get: {
                    !hasCompletedOnboarding && store.medications.isEmpty
                },
                set: { isPresented in
                    if !isPresented {
                        hasCompletedOnboarding = true
                    }
                }
            )
        ) {
            OnboardingView(
                addFirstMedication: {
                    hasCompletedOnboarding = true
                    DispatchQueue.main.async {
                        isShowingAddMedication = true
                    }
                },
                continueToApp: {
                    hasCompletedOnboarding = true
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            store.reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: .medicationsDidChangeExternally)) { _ in
            store.reload()
        }
    }
}

extension Notification.Name {
    nonisolated static let medicationsDidChangeExternally = Notification.Name("medicationsDidChangeExternally")
}

struct OnboardingView: View {
    let addFirstMedication: () -> Void
    let continueToApp: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer(minLength: 24)

                Image(systemName: "pills.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(AppTheme.accent)

                VStack(spacing: 10) {
                    Text("Pill Tracker")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Track scheduled doses, reminders, shortcut logging, and daily history on this iPhone.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }

                VStack(alignment: .leading, spacing: 16) {
                    OnboardingFeatureRow(
                        icon: "clock.badge.checkmark",
                        title: "Dose schedules",
                        text: "Set daily, selected-day, or repeated dose times."
                    )

                    OnboardingFeatureRow(
                        icon: "bell.badge",
                        title: "Optional reminders",
                        text: "Turn reminders on only for the meds that need them."
                    )

                    OnboardingFeatureRow(
                        icon: "waveform",
                        title: "Shortcut logging",
                        text: "Use private nicknames and verify logged results."
                    )
                }
                .padding()
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        addFirstMedication()
                    } label: {
                        Label("Add First Medication", systemImage: "plus.circle.fill")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button("Continue to App") {
                        continueToApp()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding()
            .background(AppTheme.pageBackground)
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct OnboardingFeatureRow: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct TodayView: View {
    let medications: [Medication]
    @Binding var isShowingAddMedication: Bool
    let updateMedication: (Medication) -> Void

    private var todayDoseItems: [TodayDoseItem] {
        medications
            .filter { $0.isScheduled(on: Date()) }
            .flatMap { medication in
                medication.doseTimes(on: Date()).map {
                    TodayDoseItem(medication: medication, doseTime: $0)
                }
            }
            .sorted { timeIndex($0.doseTime) < timeIndex($1.doseTime) }
    }

    private var takenCount: Int {
        todayDoseItems.filter { $0.medication.doseStatus(for: $0.doseTime, on: Date()) == .taken }.count
    }

    private var unsureCount: Int {
        todayDoseItems.filter { $0.medication.doseStatus(for: $0.doseTime, on: Date()) == .unsure }.count
    }

    private var skippedCount: Int {
        todayDoseItems.filter { $0.medication.doseStatus(for: $0.doseTime, on: Date()) == .skipped }.count
    }

    private var dueCount: Int {
        max(todayDoseItems.count - takenCount - unsureCount - skippedCount, 0)
    }

    var body: some View {
        NavigationStack {
            List {
                if todayDoseItems.isEmpty {
                    EmptyStateView(
                        icon: medications.isEmpty ? "pills.circle" : "checkmark.seal",
                        title: medications.isEmpty ? "No Meds Yet" : "No Meds Today",
                        message: medications.isEmpty ? "Add a medication to start tracking doses, reminders, shortcut logging, and history." : "Nothing is scheduled for today. Check History for past doses or add another medication.",
                        actionTitle: medications.isEmpty ? "Add Medication" : nil,
                        action: medications.isEmpty ? {
                            isShowingAddMedication = true
                        } : nil
                    )
                    .listRowBackground(Color.clear)
                } else {
                    Section {
                        TodaySummaryView(
                            takenCount: takenCount,
                            unsureCount: unsureCount,
                            skippedCount: skippedCount,
                            dueCount: dueCount
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                    }

                    Section("Today's Doses") {
                        ForEach(todayDoseItems) { item in
                            DoseRow(
                                medication: item.medication,
                                doseTime: item.doseTime,
                                updateMedication: updateMedication
                            )
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .navigationTitle("Today")
            .scrollContentBackground(.hidden)
            .background(AppTheme.pageBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingAddMedication = true
                    } label: {
                        Label("Add Medication", systemImage: "plus")
                    }
                }
            }
        }
    }

    private func timeIndex(_ time: String) -> Int {
        TimeOptionBuilder.fiveMinuteOptions.firstIndex(of: time) ?? 0
    }
}

struct TodayDoseItem: Identifiable {
    let medication: Medication
    let doseTime: String

    var id: String {
        "\(medication.id.uuidString)-\(doseTime)"
    }
}

struct TodaySummaryView: View {
    let takenCount: Int
    let unsureCount: Int
    let skippedCount: Int
    let dueCount: Int

    private var totalCount: Int {
        takenCount + unsureCount + skippedCount + dueCount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Today's Progress")
                        .font(.headline)

                    Text("\(takenCount) of \(totalCount) dose\(totalCount == 1 ? "" : "s") marked taken")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(totalCount == 0 ? "0%" : "\(Int((Double(takenCount) / Double(totalCount)) * 100))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(DoseStatus.taken.color)
            }

            ProgressView(value: Double(takenCount), total: Double(max(totalCount, 1)))
                .tint(DoseStatus.taken.color)

            HStack(spacing: 10) {
                HistoryCountPill(title: "Taken", count: takenCount, color: DoseStatus.taken.color)
                HistoryCountPill(title: "Not Sure", count: unsureCount, color: DoseStatus.unsure.color)
                HistoryCountPill(title: "Skipped", count: skippedCount, color: DoseStatus.skipped.color)
                HistoryCountPill(title: "Due", count: dueCount, color: DoseStatus.due.color)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [AppTheme.softAccent, Color(.systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.accent.opacity(0.14), lineWidth: 1)
        )
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 46))
                .foregroundStyle(AppTheme.accent)

            VStack(spacing: 6) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)

                Text(message)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Label(actionTitle, systemImage: "plus.circle.fill")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal)
    }
}

struct DoseRow: View {
    let medication: Medication
    let doseTime: String
    let updateMedication: (Medication) -> Void

    private var status: DoseStatus {
        medication.doseStatus(for: doseTime, on: Date())
    }

    private var updatedAt: Date? {
        medication.doseStatusUpdatedAt(for: doseTime, on: Date())
    }

    private var displayStatusText: String {
        guard status == .due else {
            return status.rawValue
        }

        return doseTimingState?.title ?? status.rawValue
    }

    private var displayStatusColor: Color {
        guard status == .due else {
            return status.color
        }

        return doseTimingState?.color ?? status.color
    }

    private var doseTimingState: DoseTimingState? {
        guard status == .due, let doseDate = DoseTimeParser.dateToday(from: doseTime) else {
            return nil
        }

        let secondsFromDoseTime = Date().timeIntervalSince(doseDate)

        if secondsFromDoseTime < -3_600 {
            return .dueLaterToday
        }

        if secondsFromDoseTime <= 1_800 {
            return .due
        }

        return .pastDue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: statusIcon)
                    .font(.title3)
                    .foregroundStyle(displayStatusColor)
                    .frame(width: 32, height: 32)
                    .background(displayStatusColor.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.siriNickname)
                        .font(.headline)

                    Text(medication.realName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(displayStatusText)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(displayStatusColor.opacity(0.26))
                    .foregroundStyle(displayStatusColor)
                    .clipShape(Capsule())
            }

            HStack(spacing: 8) {
                DoseDetailChip(icon: "clock", text: doseTime)
                DoseDetailChip(icon: "pills", text: medication.dose)
            }

            if status != .due, let updatedAt {
                Label("Updated \(DoseHistory.displayUpdateTime(updatedAt))", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button {
                    markTaken()
                } label: {
                    Label(
                        status == .taken ? "Clear Taken" : "Mark Taken",
                        systemImage: status == .taken ? "arrow.uturn.backward.circle" : "checkmark.circle.fill"
                    )
                    .font(.caption)
                    .fontWeight(.semibold)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(status == .taken ? .secondary : AppTheme.accent)

                Button {
                    markUnsure()
                } label: {
                    Label(
                        status == .unsure ? "Clear Not Sure" : "Not Sure",
                        systemImage: status == .unsure ? "xmark.circle" : "questionmark.circle"
                    )
                    .font(.caption)
                    .fontWeight(.semibold)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(status == .unsure ? .secondary : DoseStatus.unsure.color)

                Button {
                    toggleStatus(.skipped)
                } label: {
                    Label(
                        status == .skipped ? "Clear Skipped" : "Skip",
                        systemImage: status == .skipped ? "xmark.circle" : "forward.circle"
                    )
                    .font(.caption)
                    .fontWeight(.semibold)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(status == .skipped ? .secondary : DoseStatus.skipped.color)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private var statusIcon: String {
        switch status {
        case .taken:
            return "checkmark.circle.fill"
        case .unsure:
            return "questionmark.circle.fill"
        case .skipped:
            return "forward.circle.fill"
        case .due:
            switch doseTimingState {
            case .pastDue:
                return "exclamationmark.circle.fill"
            case .dueLaterToday:
                return "clock.fill"
            case .due, .none:
                return "bell.circle.fill"
            }
        }
    }

    private func markTaken() {
        toggleStatus(.taken)
    }

    private func markUnsure() {
        toggleStatus(.unsure)
    }

    private func toggleStatus(_ newStatus: DoseStatus) {
        var updatedMedication = medication
        updatedMedication.setDoseStatus(status == newStatus ? nil : newStatus, for: doseTime)
        updateMedication(updatedMedication)
    }
}

struct DoseDetailChip: View {
    let icon: String
    let text: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.secondarySystemGroupedBackground), in: Capsule())
    }
}

enum DoseTimingState {
    case dueLaterToday
    case due
    case pastDue

    var title: String {
        switch self {
        case .dueLaterToday:
            return "Due later today"
        case .due:
            return "Due"
        case .pastDue:
            return "Past due"
        }
    }

    var color: Color {
        DoseStatus.due.color
    }
}

enum DoseTimeParser {
    nonisolated static func dateToday(from time: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"

        guard let parsedTime = formatter.date(from: time) else {
            return nil
        }

        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: parsedTime)
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())

        var components = DateComponents()
        components.year = todayComponents.year
        components.month = todayComponents.month
        components.day = todayComponents.day
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute

        return calendar.date(from: components)
    }
}

struct MedicationsView: View {
    let medications: [Medication]
    @Binding var isShowingAddMedication: Bool
    @Binding var medicationToEdit: Medication?
    let deleteMedication: (Medication) -> Void

    var body: some View {
        NavigationStack {
            List {
                if medications.isEmpty {
                    EmptyStateView(
                        icon: "pills.circle",
                        title: "No Medications",
                        message: "Add your first medication, choose its schedule, and decide whether reminders should be on.",
                        actionTitle: "Add Medication",
                        action: {
                            isShowingAddMedication = true
                        }
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(medications) { medication in
                        Button {
                            medicationToEdit = medication
                        } label: {
                            MedicationManagementRow(medication: medication)
                        }
                        .buttonStyle(.plain)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
                        .listRowBackground(Color.clear)
                        .swipeActions {
                            Button(role: .destructive) {
                                deleteMedication(medication)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Meds")
            .scrollContentBackground(.hidden)
            .background(AppTheme.pageBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingAddMedication = true
                    } label: {
                        Label("Add Medication", systemImage: "plus")
                    }
                }
            }
        }
    }
}

struct MedicationManagementRow: View {
    let medication: Medication

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.realName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Private shortcut name: \(medication.siriNickname)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 3)
            }

            VStack(alignment: .leading, spacing: 7) {
                Label(medication.dose, systemImage: "pills")
                Label(medication.scheduleSummary, systemImage: "clock")
                Label(medication.daySummary, systemImage: "calendar")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            ReminderStatusBadge(enabled: medication.remindersEnabled)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

struct ReminderStatusBadge: View {
    let enabled: Bool

    var body: some View {
        Label(enabled ? "Reminders On" : "Reminders Off", systemImage: enabled ? "bell.fill" : "bell.slash")
            .font(.caption.weight(.semibold))
            .foregroundStyle(enabled ? AppTheme.accent : .secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background((enabled ? AppTheme.accent : Color.secondary).opacity(0.12), in: Capsule())
    }
}

struct MedicationFormView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    var medication: Medication?
    let existingNicknames: [String]
    let onSave: (Medication) -> Void
    let onDelete: ((Medication) -> Void)?

    @State private var realName = ""
    @State private var dose = ""
    @State private var siriNickname = ""
    @State private var scheduleKind = ScheduleKind.onceDaily
    @State private var doseTime = "8:00 AM"
    @State private var secondDoseTime = "8:00 PM"
    @State private var selectedSpecificTime = "8:00 AM"
    @State private var specificDoseTimes: [String] = []
    @State private var intervalHours = 4
    @State private var intervalStartTime = "8:00 AM"
    @State private var intervalEndTime = "8:00 PM"
    @State private var intervalStartDate = Date()
    @State private var intervalFinishDate = Date().addingTimeInterval(12 * 3_600)
    @State private var dayScheduleKind = DayScheduleKind.everyDay
    @State private var selectedWeekdays = Set(Weekday.allCases.map(\.id))
    @State private var remindersEnabled = true
    @State private var isShowingDeleteConfirmation = false

    private let intervalChoices = [1, 2, 3, 4, 6, 8, 12]
    private let timeOptions = TimeOptionBuilder.fiveMinuteOptions

    init(
        title: String,
        medication: Medication? = nil,
        existingNicknames: [String],
        onSave: @escaping (Medication) -> Void,
        onDelete: ((Medication) -> Void)? = nil
    ) {
        self.title = title
        self.medication = medication
        self.existingNicknames = existingNicknames
        self.onSave = onSave
        self.onDelete = onDelete

        _realName = State(initialValue: medication?.realName ?? "")
        _dose = State(initialValue: medication?.dose ?? "")
        _siriNickname = State(initialValue: medication?.siriNickname ?? "")
        _scheduleKind = State(initialValue: medication?.scheduleKind ?? .onceDaily)
        _doseTime = State(initialValue: medication?.displayDoseTimes.first ?? "8:00 AM")
        _secondDoseTime = State(initialValue: medication?.displayDoseTimes.dropFirst().first ?? "8:00 PM")
        _specificDoseTimes = State(initialValue: medication?.displayDoseTimes ?? ["8:00 AM"])
        _intervalHours = State(initialValue: medication?.intervalHours ?? 4)
        _intervalStartTime = State(initialValue: medication?.intervalStartTime ?? "8:00 AM")
        _intervalEndTime = State(initialValue: medication?.intervalEndTime ?? "8:00 PM")
        _intervalStartDate = State(initialValue: medication?.intervalStartDate ?? Date())
        _intervalFinishDate = State(initialValue: medication?.intervalFinishDate ?? Date().addingTimeInterval(12 * 3_600))
        _dayScheduleKind = State(initialValue: medication?.dayScheduleKind ?? .everyDay)
        _selectedWeekdays = State(initialValue: Set(medication?.selectedWeekdays ?? Weekday.allCases.map(\.id)))
        _remindersEnabled = State(initialValue: medication?.remindersEnabled ?? true)
    }

    private var trimmedRealName: String {
        realName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedDose: String {
        dose.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedNickname: String {
        siriNickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var nicknameAlreadyExists: Bool {
        existingNicknames.contains { nickname in
            nickname.caseInsensitiveCompare(trimmedNickname) == .orderedSame
        }
    }

    private var canSave: Bool {
        !trimmedRealName.isEmpty &&
        !trimmedDose.isEmpty &&
        !trimmedNickname.isEmpty &&
        !nicknameAlreadyExists &&
        !calculatedDoseTimes.isEmpty &&
        (scheduleKind != .everyXHours || intervalFinishDate >= intervalStartDate) &&
        (scheduleKind == .everyXHours || dayScheduleKind == .everyDay || !selectedWeekdays.isEmpty)
    }

    private var calculatedDoseTimes: [String] {
        switch scheduleKind {
        case .onceDaily:
            return [doseTime]
        case .twiceDaily:
            return Array(Set([doseTime, secondDoseTime])).sorted { timeIndex($0) < timeIndex($1) }
        case .specificTimes:
            return specificDoseTimes.sorted { timeIndex($0) < timeIndex($1) }
        case .everyXHours:
            return generatedIntervalDoseTimes()
        }
    }

    private var saveGuidance: String? {
        if trimmedRealName.isEmpty {
            return "Add the medication name to save."
        }

        if trimmedDose.isEmpty {
            return "Add the dose to save."
        }

        if trimmedNickname.isEmpty {
            return "Add a private shortcut name to save."
        }

        if nicknameAlreadyExists {
            return "Choose a private shortcut name that is not already being used."
        }

        if calculatedDoseTimes.isEmpty {
            return scheduleKind == .everyXHours ? "Choose a finish after the start." : "Choose at least one dose time."
        }

        if dayScheduleKind == .specificDays && selectedWeekdays.isEmpty {
            return "Choose at least one day."
        }

        return nil
    }

    private var selectedDaysSummary: String {
        switch dayScheduleKind {
        case .everyDay:
            return "Scheduled every day."
        case .specificDays:
            let days = Weekday.allCases
                .filter { selectedWeekdays.contains($0.id) }
                .map(\.shortName)
                .joined(separator: ", ")

            return days.isEmpty ? "No days selected." : "Scheduled on \(days)."
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    formSection("Medication") {
                        TextField("Medication name", text: $realName)
                            .textFieldStyle(.roundedBorder)
                        TextField("Dose, such as 2 pills or 10 mg", text: $dose)
                            .textFieldStyle(.roundedBorder)
                    }

                    formSection("Dose Schedule") {
                        Picker("Schedule", selection: $scheduleKind) {
                            ForEach(ScheduleKind.allCases) { schedule in
                                Text(schedule.rawValue).tag(schedule)
                            }
                        }

                        if scheduleKind == .specificTimes {
                            DoseTimesPreview(times: calculatedDoseTimes, deleteTime: deleteSpecificTime)
                        } else {
                            DoseTimesPreview(times: previewDoseTimes)
                        }

                        switch scheduleKind {
                        case .onceDaily:
                            timePicker("Time", selection: $doseTime)
                        case .twiceDaily:
                            timePicker("First dose", selection: $doseTime)
                            timePicker("Second dose", selection: $secondDoseTime)
                        case .specificTimes:
                            timePicker("Add time", selection: $selectedSpecificTime)

                            Button {
                                addSpecificTime()
                            } label: {
                                Label("Add Time", systemImage: "plus.circle")
                            }

                        case .everyXHours:
                            Picker("Every", selection: $intervalHours) {
                                ForEach(intervalChoices, id: \.self) { hours in
                                    Text("\(hours) hour\(hours == 1 ? "" : "s")").tag(hours)
                                }
                            }

                            DatePicker("Start", selection: $intervalStartDate, displayedComponents: [.date, .hourAndMinute])
                            DatePicker("Finish", selection: $intervalFinishDate, displayedComponents: [.date, .hourAndMinute])

                            Text(intervalSummary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if scheduleKind != .everyXHours {
                    formSection("Days") {
                        Toggle("Only certain days", isOn: specificDaysBinding)

                        Text(selectedDaysSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if dayScheduleKind == .specificDays {
                            WeekdayPicker(selectedWeekdays: $selectedWeekdays)

                            if selectedWeekdays.isEmpty {
                                Text("Choose at least one day.")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    }

                    formSection("Reminders") {
                        Toggle("Send reminders", isOn: $remindersEnabled)

                        Text(remindersEnabled ? "Notifications will be scheduled for this medication's dose times." : "No notifications will be scheduled for this medication.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    formSection("Private Shortcut Name") {
                        TextField("Example: sugar pill", text: $siriNickname)
                            .textFieldStyle(.roundedBorder)

                        Text("Use a private nickname for shortcut logging instead of the real medication name.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if nicknameAlreadyExists {
                            Text("That shortcut nickname is already being used.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }

                    if let saveGuidance {
                        Label(saveGuidance, systemImage: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if medication != nil {
                        Button(role: .destructive) {
                            isShowingDeleteConfirmation = true
                        } label: {
                            Label("Delete Medication", systemImage: "trash")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }
                .padding()
            }
            .background(AppTheme.pageBackground)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMedicationChanges()
                    }
                    .disabled(!canSave)
                }
            }
            .confirmationDialog(
                "Delete Medication?",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Medication", role: .destructive) {
                    deleteMedication()
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes the medication and its saved history.")
            }
        }
    }

    private func formSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: sectionIcon(for: title))
                .font(.headline)
                .foregroundStyle(AppTheme.accent)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppTheme.accent.opacity(0.10), lineWidth: 1)
            )
        }
    }

    private func sectionIcon(for title: String) -> String {
        switch title {
        case "Medication":
            return "pills"
        case "Dose Schedule":
            return "clock"
        case "Days":
            return "calendar"
        case "Reminders":
            return "bell"
        case "Private Shortcut Name":
            return "waveform"
        default:
            return "circle"
        }
    }

    private var specificDaysBinding: Binding<Bool> {
        Binding(
            get: {
                dayScheduleKind == .specificDays
            },
            set: { isSpecific in
                dayScheduleKind = isSpecific ? .specificDays : .everyDay

                if isSpecific && selectedWeekdays.isEmpty {
                    selectedWeekdays = Set(Weekday.allCases.map(\.id))
                }
            }
        )
    }

    private func saveMedicationChanges() {
        var savedMedication = medication ?? Medication(
            realName: trimmedRealName,
            dose: trimmedDose,
            siriNickname: trimmedNickname,
            doseTime: calculatedDoseTimes.first ?? doseTime
        )
        savedMedication.realName = trimmedRealName
        savedMedication.dose = trimmedDose
        savedMedication.siriNickname = trimmedNickname
        savedMedication.scheduleKind = scheduleKind
        savedMedication.doseTimes = calculatedDoseTimes
        savedMedication.doseTime = calculatedDoseTimes.first ?? doseTime
        savedMedication.intervalHours = intervalHours
        savedMedication.intervalStartTime = intervalStartTime
        savedMedication.intervalEndTime = intervalEndTime
        savedMedication.intervalStartDate = scheduleKind == .everyXHours ? intervalStartDate : nil
        savedMedication.intervalFinishDate = scheduleKind == .everyXHours ? intervalFinishDate : nil
        savedMedication.dayScheduleKind = dayScheduleKind
        savedMedication.selectedWeekdays = selectedWeekdays.sorted()
        savedMedication.remindersEnabled = remindersEnabled
        savedMedication.takenDoseTimesToday = savedMedication.takenDoseTimesToday.filter {
            calculatedDoseTimes.contains($0)
        }
        savedMedication.unsureDoseTimesToday = savedMedication.unsureDoseTimesToday.filter {
            calculatedDoseTimes.contains($0)
        }
        savedMedication.doseStatusHistory = savedMedication.doseStatusHistory.compactMapValues { statuses in
            let filteredStatuses = statuses.filter { calculatedDoseTimes.contains($0.key) }
            return filteredStatuses.isEmpty ? nil : filteredStatuses
        }
        savedMedication.doseStatusUpdatedAtHistory = savedMedication.doseStatusUpdatedAtHistory.compactMapValues { timestamps in
            let filteredTimestamps = timestamps.filter { calculatedDoseTimes.contains($0.key) }
            return filteredTimestamps.isEmpty ? nil : filteredTimestamps
        }
        savedMedication.doseStatusLogHistory = savedMedication.doseStatusLogHistory.compactMapValues { logs in
            let filteredLogs = logs.filter { calculatedDoseTimes.contains($0.key) }
            return filteredLogs.isEmpty ? nil : filteredLogs
        }

        onSave(savedMedication)
        dismiss()
    }

    private func deleteMedication() {
        guard let medication else {
            return
        }

        onDelete?(medication)
        dismiss()
    }

    private func timePicker(_ title: String, selection: Binding<String>) -> some View {
        Picker(title, selection: selection) {
            ForEach(timeOptions, id: \.self) { time in
                Text(time).tag(time)
            }
        }
    }

    private func addSpecificTime() {
        guard !specificDoseTimes.contains(selectedSpecificTime) else {
            return
        }

        specificDoseTimes.append(selectedSpecificTime)
        specificDoseTimes.sort { timeIndex($0) < timeIndex($1) }
    }

    private func deleteSpecificTime(_ time: String) {
        specificDoseTimes.removeAll { $0 == time }
    }

    private func generatedIntervalDoseTimes() -> [String] {
        intervalOccurrenceDates.map { Self.timeFormatter.string(from: $0) }
    }

    private var intervalOccurrenceDates: [Date] {
        guard intervalFinishDate >= intervalStartDate else { return [] }
        let step = TimeInterval(max(intervalHours, 1) * 3_600)
        var dates: [Date] = []
        var date = intervalStartDate
        while date <= intervalFinishDate {
            dates.append(date)
            date = date.addingTimeInterval(step)
        }
        return dates
    }

    private var previewDoseTimes: [String] {
        guard scheduleKind == .everyXHours else { return calculatedDoseTimes }
        return intervalOccurrenceDates.map { Self.previewFormatter.string(from: $0) }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private static let previewFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d, h:mm a"
        return formatter
    }()

    private var intervalSummary: String {
        let times = calculatedDoseTimes

        guard let firstTime = times.first, let lastTime = times.last else {
            return "No times generated. Choose an end time after the start time."
        }

        return "\(times.count) doses: \(firstTime) to \(lastTime)"
    }

    private func timeIndex(_ time: String) -> Int {
        timeOptions.firstIndex(of: time) ?? 0
    }
}

enum TimeOptionBuilder {
    static let fiveMinuteOptions: [String] = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        return stride(from: 0, to: 24 * 60, by: 5).compactMap { minuteOffset in
            guard let date = calendar.date(byAdding: .minute, value: minuteOffset, to: startOfDay) else {
                return nil
            }

            return formatter.string(from: date)
        }
    }()
}

struct DoseTimesPreview: View {
    let times: [String]
    var deleteTime: ((String) -> Void)?

    private let columns = [
        GridItem(.adaptive(minimum: 96), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(times.isEmpty ? "No dose times selected." : "\(times.count) scheduled dose\(times.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)

            if !times.isEmpty {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                    ForEach(Array(times.enumerated()), id: \.offset) { _, time in
                        if let deleteTime {
                            Button {
                                deleteTime(time)
                            } label: {
                                timeChip(time, icon: "xmark.circle.fill")
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Remove \(time)")
                        } else {
                            timeChip(time, icon: "clock")
                        }
                    }
                }
            }
        }
    }

    private func timeChip(_ time: String, icon: String) -> some View {
        Label(time, systemImage: icon)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(AppTheme.accent)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(AppTheme.softAccent, in: Capsule())
    }
}

struct WeekdayPicker: View {
    @Binding var selectedWeekdays: Set<Int>

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Weekday.allCases) { weekday in
                Button {
                    toggle(weekday)
                } label: {
                    Text(weekday.shortName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(selectedWeekdays.contains(weekday.id) ? AppTheme.accent : .secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func toggle(_ weekday: Weekday) {
        if selectedWeekdays.contains(weekday.id) {
            selectedWeekdays.remove(weekday.id)
        } else {
            selectedWeekdays.insert(weekday.id)
        }
    }
}

struct HistoryView: View {
    let medications: [Medication]
    @State private var displayedMonth = Date()
    @State private var selectedDate = Date()

    private var selectedMedications: [Medication] {
        medications.filter { $0.isScheduled(on: selectedDate) }
    }

    private var takenCount: Int {
        selectedMedications.reduce(0) { total, medication in
            total + medication.doseTimes(on: selectedDate).filter {
                medication.doseStatus(for: $0, on: selectedDate) == .taken
            }.count
        }
    }

    private var unsureCount: Int {
        selectedMedications.reduce(0) { total, medication in
            total + medication.doseTimes(on: selectedDate).filter {
                medication.doseStatus(for: $0, on: selectedDate) == .unsure
            }.count
        }
    }

    private var skippedCount: Int {
        selectedMedications.reduce(0) { total, medication in
            total + medication.doseTimes(on: selectedDate).filter {
                medication.doseStatus(for: $0, on: selectedDate) == .skipped
            }.count
        }
    }

    private var totalDoseCount: Int {
        selectedMedications.reduce(0) { total, medication in
            total + medication.doseTimes(on: selectedDate).count
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    calendarHeader

                    HistoryCalendarView(
                        displayedMonth: displayedMonth,
                        selectedDate: $selectedDate,
                        medications: medications
                    )

                    selectedDaySummary

                    if selectedMedications.isEmpty {
                        ContentUnavailableView(
                            "No Doses",
                            systemImage: "calendar",
                            description: Text("No medication is scheduled for this day.")
                        )
                        .padding(.top, 24)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Dose History")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            ForEach(selectedMedications) { medication in
                                ForEach(medication.doseTimes(on: selectedDate), id: \.self) { doseTime in
                                    HistoryDoseRow(
                                        medication: medication,
                                        doseTime: doseTime,
                                        selectedDate: selectedDate
                                    )
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(AppTheme.pageBackground)
            .navigationTitle("History")
        }
    }

    private var calendarHeader: some View {
        HStack {
            Button {
                moveMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.bordered)

            Spacer()

            Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.title3)
                .fontWeight(.bold)

            Spacer()

            Button {
                moveMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.bordered)
        }
    }

    private var selectedDaySummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(DoseHistory.displayDate(selectedDate))
                .font(.headline)

            HStack(spacing: 10) {
                HistoryCountPill(title: "Taken", count: takenCount, color: DoseStatus.taken.color)
                HistoryCountPill(title: "Not Sure", count: unsureCount, color: DoseStatus.unsure.color)
                HistoryCountPill(title: "Skipped", count: skippedCount, color: DoseStatus.skipped.color)
                HistoryCountPill(
                    title: "Due",
                    count: max(totalDoseCount - takenCount - unsureCount - skippedCount, 0),
                    color: DoseStatus.due.color
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func moveMonth(by amount: Int) {
        guard let newMonth = Calendar.current.date(byAdding: .month, value: amount, to: displayedMonth) else {
            return
        }

        displayedMonth = newMonth

        if !Calendar.current.isDate(selectedDate, equalTo: newMonth, toGranularity: .month) {
            selectedDate = Calendar.current.startOfMonth(for: newMonth)
        }
    }
}

struct HistoryCalendarView: View {
    let displayedMonth: Date
    @Binding var selectedDate: Date
    let medications: [Medication]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    private var calendarDays: [Date?] {
        let calendar = Calendar.current
        let startOfMonth = calendar.startOfMonth(for: displayedMonth)
        let range = calendar.range(of: .day, in: .month, for: startOfMonth) ?? 1..<1
        let leadingSpaces = calendar.component(.weekday, from: startOfMonth) - 1
        let dates = range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }

        return Array(repeating: nil, count: leadingSpaces) + dates
    }

    var body: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { _, weekday in
                    Text(weekday)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(calendarDays.enumerated()), id: \.offset) { _, date in
                    if let date {
                        HistoryDayButton(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            status: dayStatus(for: date)
                        ) {
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func dayStatus(for date: Date) -> DoseStatus? {
        let scheduledMedications = medications.filter { $0.isScheduled(on: date) }

        guard !scheduledMedications.isEmpty else {
            return nil
        }

        let statuses = scheduledMedications.flatMap { medication in
            medication.doseTimes(on: date).map {
                medication.doseStatus(for: $0, on: date)
            }
        }

        if statuses.contains(.unsure) {
            return .unsure
        }

        if statuses.contains(.skipped) {
            return .skipped
        }

        if statuses.contains(.due) {
            return .due
        }

        return .taken
    }
}

struct HistoryDayButton: View {
    let date: Date
    let isSelected: Bool
    let status: DoseStatus?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .regular)
                    .frame(width: 34, height: 30)
                    .background(isSelected ? AppTheme.accent : Color.clear)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .clipShape(Circle())

                Circle()
                    .fill(status?.color ?? .clear)
                    .frame(width: 6, height: 6)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
    }
}

struct HistoryCountPill: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.headline)
                .fontWeight(.bold)
            Text(title)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.18))
        .foregroundStyle(color)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct HistoryDoseRow: View {
    let medication: Medication
    let doseTime: String
    let selectedDate: Date

    private var status: DoseStatus {
        medication.doseStatus(for: doseTime, on: selectedDate)
    }

    private var updatedAt: Date? {
        medication.doseStatusUpdatedAt(for: doseTime, on: selectedDate)
    }

    private var logEntries: [DoseStatusLogEntry] {
        medication.doseStatusLog(for: doseTime, on: selectedDate).reversed()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.siriNickname)
                    .font(.headline)
                Text("\(medication.realName) - \(medication.dose) - \(doseTime)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if status != .due, let updatedAt {
                    Label("Updated \(DoseHistory.displayUpdateTime(updatedAt))", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !logEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(logEntries) { entry in
                            Text("\(entry.status) at \(DoseHistory.displayUpdateTime(entry.changedAt))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 2)
                }
            }

            Spacer()

            Text(status.rawValue)
                .font(.subheadline)
                .fontWeight(.bold)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(status.color.opacity(0.22))
                .foregroundStyle(status.color)
                .clipShape(Capsule())
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? startOfDay(for: date)
    }
}

struct ShortcutsView: View {
    let medications: [Medication]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Shortcut Actions")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    ShortcutInstructionCard(title: "How to log a pill as taken, not sure, or skipped", icon: "checkmark.bubble") {
                        Text("Press and hold the upper right button on phone, then say one of the phrases below.")
                            .foregroundStyle(.secondary)

                        if medications.isEmpty {
                            Text("Add a medication to make shortcut actions available.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(medications) { medication in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(medication.siriNickname)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    ShortcutPhraseText("I took \(medication.siriNickname) in Pill Tracker")
                                    ShortcutPhraseText("I'm not sure if I took \(medication.siriNickname) in Pill Tracker")
                                    ShortcutPhraseText("Skip \(medication.siriNickname) in Pill Tracker")
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }

                    ShortcutInstructionCard(title: "How to Check Medication Status", icon: "list.bullet.clipboard") {
                        ShortcutPhraseText("Pill Tracker status report")
                        ShortcutPhraseText("Pill Tracker medication status")
                        ShortcutPhraseText("Pill Tracker pill status")
                    }

                    ShortcutInstructionCard(title: "Multiple Daily Doses", icon: "clock.badge.questionmark") {
                        Text("When one dose clearly matches the current time, the shortcut logs that dose for the medication you name.")
                        Text("If multiple close doses are unlogged, the shortcut asks which dose and includes the scheduled times, such as first dose at 8:00 AM or second dose at 12:00 PM.")
                    }

                    Text("* Always verify that shortcut logging saved the correct dose.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
                .padding()
            }
            .navigationTitle("Shortcuts")
            .background(AppTheme.pageBackground)
        }
    }
}

struct ShortcutInstructionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(AppTheme.accent)

            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .font(.subheadline)
            .foregroundStyle(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.accent.opacity(0.10), lineWidth: 1)
        )
    }
}

struct ShortcutPhraseText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text("“\(text)”")
            .foregroundStyle(.secondary)
            .padding(.vertical, 2)
    }
}

struct SettingsView: View {
    let medicationCount: Int
    let resetAllData: () -> Void

    @State private var isShowingResetConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section("Notifications") {
                    Text("Allow notifications in iPhone Settings to receive reminders.")
                }

                Section("Shortcuts") {
                    Text("Private shortcut names help avoid saying real medication names out loud.")
                    Text("Shortcut logging works through iOS system shortcuts.")
                    Text("To run shortcuts while your iPhone is locked, allow shortcut access in iPhone Settings.")
                }

                Section("Medical Disclaimer") {
                    Text("This app is for personal medication tracking only. It is not medical advice and does not replace guidance from a doctor, pharmacist, or other healthcare provider.")
                    Text("Medication names, doses, schedules, reminders, and history depend on information entered by the user.")
                }

                Section("Data") {
                    Text("Medication data is saved on this device.")
                    Label("\(medicationCount) medication\(medicationCount == 1 ? "" : "s") saved", systemImage: "pills")

                    Button(role: .destructive) {
                        isShowingResetConfirmation = true
                    } label: {
                        Label("Delete All Medications & History", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Settings")
            .scrollContentBackground(.hidden)
            .background(AppTheme.pageBackground)
            .confirmationDialog(
                "Delete All Medications & History?",
                isPresented: $isShowingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive) {
                    resetAllData()
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes all saved medications, history, and pending reminders.")
            }
        }
    }
}
