//
//  Pending.swift
//  SemenCheck
//
//  Cola mínima para no perder auditorías ni paquetes si falla la red.
//

import Foundation

final class Pending {
    static let shared = Pending()

    private struct HarvestItem: Codable { let meta: HarvestMeta; let file: String }
    private struct Store: Codable { var audits: [AuditRequest] = []; var harvests: [HarvestItem] = [] }

    private let fm = FileManager.default
    private var store = Store()

    init() { load() }

    private var indexURL: URL { documents.appendingPathComponent("pending.json") }

    private func load() {
        guard let data = try? Data(contentsOf: indexURL),
              let decoded = try? JSONDecoder().decode(Store.self, from: data) else { return }
        store = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(store) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }

    func addAudit(_ body: AuditRequest) {
        store.audits.append(body)
        save()
    }

    func addHarvest(meta: HarvestMeta, zip: URL?) {
        guard let zip else { return }
        let destination = documents.appendingPathComponent("pending-\(UUID().uuidString).zip")
        try? fm.moveItem(at: zip, to: destination)
        store.harvests.append(HarvestItem(meta: meta, file: destination.lastPathComponent))
        save()
    }

    var isEmpty: Bool { store.audits.isEmpty && store.harvests.isEmpty }

    func flush(api: API) async {
        for body in store.audits {
            if (try? await api.audit(body)) != nil {
                store.audits.removeAll { $0.phrase == body.phrase }
                save()
            }
        }
        for item in store.harvests {
            let url = documents.appendingPathComponent(item.file)
            if (try? await api.upload(meta: item.meta, zip: url)) != nil {
                try? fm.removeItem(at: url)
                store.harvests.removeAll { $0.file == item.file }
                save()
            }
        }
    }

    private var documents: URL {
        fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
