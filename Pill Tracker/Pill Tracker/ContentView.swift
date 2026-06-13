//
//  ContentView.swift
//  Pill Tracker
//
//  Created by Jose Gonzalez on 6/11/26.
//

import SwiftUI

enum DoseStatus: String, Codable {
    case due = "Due"
    case taken = "Taken"
    case unsure = "Not Sure"

    var color: Color {
        switch self {
        case .due:
            return .orange
        case .taken:
            return .green
        case .unsure:
            return Color(red: 0.43, green: 0.39, blue: 0.58)
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
    nonisolated func isScheduled(on date: Date) -> Bool {
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

        if Calendar.current.isDateInToday(date) {
            if takenDoseTimesToday.contains(doseTime) {
                return .taken
            }

            if unsureDoseTimesToday.contains(doseTime) {
                return .unsure
            }
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
                updateMedication: store.update,
                deleteMedication: store.delete
            )
            .tabItem {
                Label("Meds", systemImage: "pills")
            }

            HistoryView(medications: store.medications)
                .tabItem {
                    Label("History", systemImage: "calendar")
                }

            SiriView(medications: store.medications)
                .tabItem {
                    Label("Siri", systemImage: "waveform")
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

struct TodayView: View {
    let medications: [Medication]
    @Binding var isShowingAddMedication: Bool
    let updateMedication: (Medication) -> Void

    private var todaysMedications: [Medication] {
        medications.filter { $0.isScheduled(on: Date()) }
    }

    var body: some View {
        NavigationStack {
            List {
                if todaysMedications.isEmpty {
                    ContentUnavailableView(
                        medications.isEmpty ? "No Meds Yet" : "No Meds Today",
                        systemImage: "pills",
                        description: Text(medications.isEmpty ? "Tap the plus button to add your first medication." : "Nothing is scheduled for today.")
                    )
                } else {
                    Section("Today's Doses") {
                        ForEach(todaysMedications) { medication in
                            ForEach(medication.displayDoseTimes, id: \.self) { doseTime in
                                DoseRow(
                                    medication: medication,
                                    doseTime: doseTime,
                                    updateMedication: updateMedication
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Today")
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

    private var recentLogEntries: [DoseStatusLogEntry] {
        Array(medication.doseStatusLog(for: doseTime, on: Date()).suffix(3).reversed())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(medication.siriNickname)
                    .font(.headline)

                Spacer()

                Text(status.rawValue)
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(status.color.opacity(0.26))
                    .foregroundStyle(status.color)
                    .clipShape(Capsule())
            }

            Text("\(medication.realName) - \(medication.dose) - \(doseTime)")
                .foregroundStyle(.secondary)

            if status != .due, let updatedAt {
                Label("Updated \(DoseHistory.displayUpdateTime(updatedAt))", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !recentLogEntries.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(recentLogEntries) { entry in
                        Text("\(entry.status) at \(DoseHistory.displayUpdateTime(entry.changedAt))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack {
                Button {
                    markTaken()
                } label: {
                    Label(
                        status == .taken ? "Undo" : "Mark Taken",
                        systemImage: status == .taken ? "arrow.uturn.backward.circle" : "checkmark.circle.fill"
                    )
                    .font(.caption)
                    .fontWeight(.semibold)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(status == .taken ? .secondary : .blue)

                Button {
                    markUnsure()
                } label: {
                    Label(
                        status == .unsure ? "Clear" : "Not Sure",
                        systemImage: status == .unsure ? "xmark.circle" : "questionmark.circle"
                    )
                    .font(.caption)
                    .fontWeight(.semibold)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(status == .unsure ? .secondary : DoseStatus.unsure.color)
            }
        }
        .padding(.vertical, 6)
    }

    private func markTaken() {
        var updatedMedication = medication
        let todayKey = DoseHistory.dateKey(for: Date())
        var todaysStatuses = updatedMedication.doseStatusHistory[todayKey] ?? [:]
        var todaysUpdatedAt = updatedMedication.doseStatusUpdatedAtHistory[todayKey] ?? [:]
        var todaysLog = updatedMedication.doseStatusLogHistory[todayKey] ?? [:]

        updatedMedication.unsureDoseTimesToday.removeAll { $0 == doseTime }

        if updatedMedication.takenDoseTimesToday.contains(doseTime) ||
            todaysStatuses[doseTime] == DoseStatus.taken.rawValue {
            updatedMedication.takenDoseTimesToday.removeAll { $0 == doseTime }
            todaysStatuses.removeValue(forKey: doseTime)
            todaysUpdatedAt.removeValue(forKey: doseTime)
            addLogEntry("Cleared", doseTime: doseTime, todaysLog: &todaysLog)
        } else {
            updatedMedication.takenDoseTimesToday.append(doseTime)
            todaysStatuses[doseTime] = DoseStatus.taken.rawValue
            todaysUpdatedAt[doseTime] = Date()
            addLogEntry(DoseStatus.taken.rawValue, doseTime: doseTime, todaysLog: &todaysLog)
        }

        updatedMedication.doseStatusHistory[todayKey] = todaysStatuses.isEmpty ? nil : todaysStatuses
        updatedMedication.doseStatusUpdatedAtHistory[todayKey] = todaysUpdatedAt.isEmpty ? nil : todaysUpdatedAt
        updatedMedication.doseStatusLogHistory[todayKey] = todaysLog.isEmpty ? nil : todaysLog
        updateMedication(updatedMedication)
    }

    private func markUnsure() {
        var updatedMedication = medication
        let todayKey = DoseHistory.dateKey(for: Date())
        var todaysStatuses = updatedMedication.doseStatusHistory[todayKey] ?? [:]
        var todaysUpdatedAt = updatedMedication.doseStatusUpdatedAtHistory[todayKey] ?? [:]
        var todaysLog = updatedMedication.doseStatusLogHistory[todayKey] ?? [:]

        updatedMedication.takenDoseTimesToday.removeAll { $0 == doseTime }

        if updatedMedication.unsureDoseTimesToday.contains(doseTime) ||
            todaysStatuses[doseTime] == DoseStatus.unsure.rawValue {
            updatedMedication.unsureDoseTimesToday.removeAll { $0 == doseTime }
            todaysStatuses.removeValue(forKey: doseTime)
            todaysUpdatedAt.removeValue(forKey: doseTime)
            addLogEntry("Cleared", doseTime: doseTime, todaysLog: &todaysLog)
        } else {
            updatedMedication.unsureDoseTimesToday.append(doseTime)
            todaysStatuses[doseTime] = DoseStatus.unsure.rawValue
            todaysUpdatedAt[doseTime] = Date()
            addLogEntry(DoseStatus.unsure.rawValue, doseTime: doseTime, todaysLog: &todaysLog)
        }

        updatedMedication.doseStatusHistory[todayKey] = todaysStatuses.isEmpty ? nil : todaysStatuses
        updatedMedication.doseStatusUpdatedAtHistory[todayKey] = todaysUpdatedAt.isEmpty ? nil : todaysUpdatedAt
        updatedMedication.doseStatusLogHistory[todayKey] = todaysLog.isEmpty ? nil : todaysLog
        updateMedication(updatedMedication)
    }

    private func addLogEntry(_ status: String, doseTime: String, todaysLog: inout [String: [DoseStatusLogEntry]]) {
        var entries = todaysLog[doseTime] ?? []
        entries.append(DoseStatusLogEntry(status: status, changedAt: Date()))
        todaysLog[doseTime] = Array(entries.suffix(20))
    }
}

struct MedicationsView: View {
    let medications: [Medication]
    @Binding var isShowingAddMedication: Bool
    @Binding var medicationToEdit: Medication?
    let updateMedication: (Medication) -> Void
    let deleteMedication: (Medication) -> Void

    var body: some View {
        NavigationStack {
            List {
                if medications.isEmpty {
                    ContentUnavailableView(
                        "No Medications",
                        systemImage: "pills",
                        description: Text("Add a medication to start tracking doses.")
                    )
                } else {
                    ForEach(medications) { medication in
                        Button {
                            medicationToEdit = medication
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(medication.realName)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text("Siri name: \(medication.siriNickname)")
                                        .foregroundStyle(.secondary)
                                    Text("\(medication.dose) - \(medication.scheduleSummary)")
                                        .foregroundStyle(.secondary)
                                    Text(medication.daySummary)
                                        .foregroundStyle(.secondary)
                                    Label(
                                        medication.remindersEnabled ? "Reminders on" : "Reminders off",
                                        systemImage: medication.remindersEnabled ? "bell" : "bell.slash"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(medication.remindersEnabled ? .blue : .secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 6)
                        .swipeActions {
                            Button {
                                var updatedMedication = medication
                                updatedMedication.isTakenToday.toggle()
                                updateMedication(updatedMedication)
                            } label: {
                                Label(
                                    medication.isTakenToday ? "Undo" : "Taken",
                                    systemImage: medication.isTakenToday ? "arrow.uturn.backward.circle" : "checkmark.circle"
                                )
                            }
                            .tint(.green)

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
        (dayScheduleKind == .everyDay || !selectedWeekdays.isEmpty)
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    formSection("Medication") {
                    TextField("Real name", text: $realName)
                        .textFieldStyle(.roundedBorder)
                    TextField("Dose", text: $dose)
                        .textFieldStyle(.roundedBorder)
                }

                    formSection("Private Siri Name") {
                    TextField("Example: sugar pill", text: $siriNickname)
                        .textFieldStyle(.roundedBorder)

                    if nicknameAlreadyExists {
                        Text("That Siri nickname is already being used.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                    formSection("Days") {
                    Toggle("Specific days", isOn: specificDaysBinding)

                    if dayScheduleKind == .specificDays {
                        WeekdayPicker(selectedWeekdays: $selectedWeekdays)

                        if selectedWeekdays.isEmpty {
                            Text("Choose at least one day.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }

                    formSection("Reminders") {
                        Toggle("Send reminders", isOn: $remindersEnabled)

                        Text(remindersEnabled ? "Notifications will be scheduled for this medication's dose times." : "No notifications will be scheduled for this medication.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    formSection("Dose Time") {
                    Picker("Schedule", selection: $scheduleKind) {
                        ForEach(ScheduleKind.allCases) { schedule in
                            Text(schedule.rawValue).tag(schedule)
                        }
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

                        TimeChipGrid(
                            times: calculatedDoseTimes,
                            deleteTime: deleteSpecificTime
                        )
                    case .everyXHours:
                        Picker("Every", selection: $intervalHours) {
                            ForEach(intervalChoices, id: \.self) { hours in
                                Text("\(hours) hour\(hours == 1 ? "" : "s")").tag(hours)
                            }
                        }

                        timePicker("Start", selection: $intervalStartTime)
                        timePicker("End", selection: $intervalEndTime)

                        Text(intervalSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
            .background(Color(.systemGroupedBackground))
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
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
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
        let startIndex = timeIndex(intervalStartTime)
        let endIndex = timeIndex(intervalEndTime)

        guard startIndex <= endIndex else {
            return []
        }

        let step = max(intervalHours, 1) * 12
        return stride(from: startIndex, through: endIndex, by: step).map { timeOptions[$0] }
    }

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

struct TimeChipGrid: View {
    let times: [String]
    let deleteTime: (String) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 92), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(times, id: \.self) { time in
                Button(role: .destructive) {
                    deleteTime(time)
                } label: {
                    HStack(spacing: 6) {
                        Text(time)
                            .font(.caption)
                            .fontWeight(.semibold)

                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
            }
        }
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
                .tint(selectedWeekdays.contains(weekday.id) ? .blue : .secondary)
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
            total + medication.displayDoseTimes.filter {
                medication.doseStatus(for: $0, on: selectedDate) == .taken
            }.count
        }
    }

    private var unsureCount: Int {
        selectedMedications.reduce(0) { total, medication in
            total + medication.displayDoseTimes.filter {
                medication.doseStatus(for: $0, on: selectedDate) == .unsure
            }.count
        }
    }

    private var totalDoseCount: Int {
        selectedMedications.reduce(0) { total, medication in
            total + medication.displayDoseTimes.count
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
                                ForEach(medication.displayDoseTimes, id: \.self) { doseTime in
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
            .background(Color(.systemGroupedBackground))
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
                HistoryCountPill(
                    title: "Due",
                    count: max(totalDoseCount - takenCount - unsureCount, 0),
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
            medication.displayDoseTimes.map {
                medication.doseStatus(for: $0, on: date)
            }
        }

        if statuses.contains(.unsure) {
            return .unsure
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
                    .background(isSelected ? Color.blue : Color.clear)
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

struct SiriView: View {
    let medications: [Medication]

    var body: some View {
        NavigationStack {
            List {
                Section("Siri Actions") {
                    if medications.isEmpty {
                        Text("Add a medication to make Siri actions available.")
                    } else {
                        ForEach(medications) { medication in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(medication.siriNickname)
                                    .font(.headline)

                                Text("I took \(medication.siriNickname) in Pill Tracker")
                                Text("I'm not sure if I took \(medication.siriNickname) in Pill Tracker")
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section("Check Due") {
                    Text("Did I take my pills in Pill Tracker")
                    Text("What meds are due in Pill Tracker")
                }

                Section("Dose Number") {
                    Text("I took my first dose today in Pill Tracker")
                    Text("I took my second dose today in Pill Tracker")
                    Text("Mark my third dose as taken in Pill Tracker")
                }

                Section("Privacy") {
                    Text("Siri uses nicknames instead of real medication names.")
                }
            }
            .navigationTitle("Siri")
        }
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

                Section("Siri") {
                    Text("Private Siri names help avoid saying real medication names out loud.")
                    Text("Allow Siri in iPhone Settings so voice logging can communicate with Pill Tracker.")
                    Text("To use Siri while your iPhone is locked, turn on Siri under Allow Access When Locked in Face ID & Passcode settings.")
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
