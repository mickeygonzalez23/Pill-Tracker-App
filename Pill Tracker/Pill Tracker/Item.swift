//
//  Item.swift
//  Pill Tracker
//
//  Created by Jose Gonzalez on 6/11/26.
//

import Combine
import Foundation

struct Medication: Identifiable, Codable, Equatable {
    var id = UUID()
    var realName: String
    var dose: String
    var siriNickname: String
    var doseTime: String
    var isTakenToday: Bool = false
    var createdAt = Date()
}

final class MedicationStore: ObservableObject {
    @Published var medications: [Medication] = [] {
        didSet {
            save()
        }
    }

    private let storageKey = "savedMedications"

    init() {
        load()
    }

    func add(_ medication: Medication) {
        medications.append(medication)
    }

    func update(_ medication: Medication) {
        guard let index = medications.firstIndex(where: { $0.id == medication.id }) else {
            return
        }

        medications[index] = medication
    }

    func delete(_ medication: Medication) {
        medications.removeAll { $0.id == medication.id }
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let savedMedications = try? JSONDecoder().decode([Medication].self, from: data)
        else {
            return
        }

        medications = savedMedications
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(medications) else {
            return
        }

        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
