//
//  ContentView.swift
//  Pill Tracker
//
//  Created by Jose Gonzalez on 6/11/26.
//

import SwiftUI

struct MedicationDose: Identifiable {
    let id = UUID()
    let nickname: String
    let realName: String
    let dose: String
    let timeLabel: String
    let status: DoseStatus
}

enum DoseStatus: String {
    case due = "Due"
    case next = "Next"
    case taken = "Taken"

    var color: Color {
        switch self {
        case .due:
            return .orange
        case .next:
            return .blue
        case .taken:
            return .green
        }
    }
}

struct ContentView: View {
    private let todayDoses = [
        MedicationDose(
            nickname: "sugar pill dose 1",
            realName: "Metformin",
            dose: "500 mg",
            timeLabel: "Morning",
            status: .due
        ),
        MedicationDose(
            nickname: "sugar pill dose 2",
            realName: "Metformin",
            dose: "500 mg",
            timeLabel: "Evening",
            status: .next
        ),
        MedicationDose(
            nickname: "night pill",
            realName: "Atorvastatin",
            dose: "20 mg",
            timeLabel: "Bedtime",
            status: .taken
        )
    ]

    var body: some View {
        TabView {
            TodayView(doses: todayDoses)
                .tabItem {
                    Label("Today", systemImage: "checklist")
                }

            MedicationsView(doses: todayDoses)
                .tabItem {
                    Label("Meds", systemImage: "pills")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }

            SiriView()
                .tabItem {
                    Label("Siri", systemImage: "waveform")
                }
        }
    }
}

struct TodayView: View {
    let doses: [MedicationDose]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(doses) { dose in
                        DoseRow(dose: dose)
                    }
                }
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                    } label: {
                        Label("Add Medication", systemImage: "plus")
                    }
                }
            }
        }
    }
}

struct DoseRow: View {
    let dose: MedicationDose

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dose.nickname)
                    .font(.headline)

                Spacer()

                Text(dose.status.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(dose.status.color.opacity(0.16))
                    .foregroundStyle(dose.status.color)
                    .clipShape(Capsule())
            }

            Text("\(dose.realName) - \(dose.dose) - \(dose.timeLabel)")
                .foregroundStyle(.secondary)

            Button {
            } label: {
                Label("Mark Taken", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(dose.status == .taken)
        }
        .padding(.vertical, 6)
    }
}

struct MedicationsView: View {
    let doses: [MedicationDose]

    var body: some View {
        NavigationStack {
            List {
                ForEach(doses) { dose in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(dose.realName)
                            .font(.headline)
                        Text("Siri name: \(dose.nickname)")
                            .foregroundStyle(.secondary)
                        Text("\(dose.dose) - \(dose.timeLabel)")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Meds")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                    } label: {
                        Label("Add Medication", systemImage: "plus")
                    }
                }
            }
        }
    }
}

struct HistoryView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("This Week") {
                    Label("2 doses marked taken today", systemImage: "checkmark.circle")
                    Label("1 dose due later", systemImage: "clock")
                }
            }
            .navigationTitle("History")
        }
    }
}

struct SiriView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Private Siri Phrases") {
                    Text("Hey Siri, I took my sugar pill.")
                    Text("Hey Siri, I took sugar pill dose 1.")
                    Text("Hey Siri, did I take my pills today?")
                }

                Section("Privacy") {
                    Text("Siri uses nicknames instead of real medication names.")
                }
            }
            .navigationTitle("Siri")
        }
    }
}

#Preview {
    ContentView()
}
