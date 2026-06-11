//
//  ContentView.swift
//  Pill Tracker
//
//  Created by Jose Gonzalez on 6/11/26.
//

import SwiftUI

enum DoseStatus: String {
    case due = "Due"
    case taken = "Taken"

    var color: Color {
        switch self {
        case .due:
            return .orange
        case .taken:
            return .green
        }
    }
}

struct ContentView: View {
    @StateObject private var store = MedicationStore()
    @State private var isShowingAddMedication = false

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
        }
        .sheet(isPresented: $isShowingAddMedication) {
            AddMedicationView(
                existingNicknames: store.medications.map(\.siriNickname),
                addMedication: store.add
            )
        }
    }
}

struct TodayView: View {
    let medications: [Medication]
    @Binding var isShowingAddMedication: Bool
    let updateMedication: (Medication) -> Void

    var body: some View {
        NavigationStack {
            List {
                if medications.isEmpty {
                    ContentUnavailableView(
                        "No Meds Yet",
                        systemImage: "pills",
                        description: Text("Tap the plus button to add your first medication.")
                    )
                } else {
                    Section("Today's Doses") {
                        ForEach(medications) { medication in
                            DoseRow(
                                medication: medication,
                                updateMedication: updateMedication
                            )
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
    let updateMedication: (Medication) -> Void

    private var status: DoseStatus {
        medication.isTakenToday ? .taken : .due
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(medication.siriNickname)
                    .font(.headline)

                Spacer()

                Text(status.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(status.color.opacity(0.16))
                    .foregroundStyle(status.color)
                    .clipShape(Capsule())
            }

            Text("\(medication.realName) - \(medication.dose) - \(medication.doseTime)")
                .foregroundStyle(.secondary)

            Button {
                var updatedMedication = medication
                updatedMedication.isTakenToday.toggle()
                updateMedication(updatedMedication)
            } label: {
                Label(
                    medication.isTakenToday ? "Undo Taken" : "Mark Taken",
                    systemImage: medication.isTakenToday ? "arrow.uturn.backward.circle" : "checkmark.circle.fill"
                )
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 6)
    }
}

struct MedicationsView: View {
    let medications: [Medication]
    @Binding var isShowingAddMedication: Bool
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
                        VStack(alignment: .leading, spacing: 6) {
                            Text(medication.realName)
                                .font(.headline)
                            Text("Siri name: \(medication.siriNickname)")
                                .foregroundStyle(.secondary)
                            Text("\(medication.dose) - \(medication.doseTime)")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
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

struct AddMedicationView: View {
    @Environment(\.dismiss) private var dismiss

    let existingNicknames: [String]
    let addMedication: (Medication) -> Void

    @State private var realName = ""
    @State private var dose = ""
    @State private var siriNickname = ""
    @State private var doseTime = "Morning"

    private let doseTimes = ["Morning", "Noon", "Evening", "Bedtime"]

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
        !nicknameAlreadyExists
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {
                    TextField("Real name", text: $realName)
                    TextField("Dose", text: $dose)
                }

                Section("Private Siri Name") {
                    TextField("Example: sugar pill", text: $siriNickname)

                    if nicknameAlreadyExists {
                        Text("That Siri nickname is already being used.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Dose Time") {
                    Picker("Time", selection: $doseTime) {
                        ForEach(doseTimes, id: \.self) { time in
                            Text(time)
                        }
                    }
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMedication()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func saveMedication() {
        let medication = Medication(
            realName: trimmedRealName,
            dose: trimmedDose,
            siriNickname: trimmedNickname,
            doseTime: doseTime
        )
        addMedication(medication)
        dismiss()
    }
}

struct HistoryView: View {
    let medications: [Medication]

    private var takenCount: Int {
        medications.filter(\.isTakenToday).count
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Today") {
                    Label("\(takenCount) marked taken", systemImage: "checkmark.circle")
                    Label("\(max(medications.count - takenCount, 0)) still due", systemImage: "clock")
                }
            }
            .navigationTitle("History")
        }
    }
}

struct SiriView: View {
    let medications: [Medication]

    var body: some View {
        NavigationStack {
            List {
                Section("Private Siri Phrases") {
                    if medications.isEmpty {
                        Text("Add a medication to see Siri phrase examples.")
                    } else {
                        ForEach(medications) { medication in
                            Text("Hey Siri, I took my \(medication.siriNickname).")
                        }
                    }
                }

                Section("Privacy") {
                    Text("Siri uses nicknames instead of real medication names.")
                }
            }
            .navigationTitle("Siri")
        }
    }
}
