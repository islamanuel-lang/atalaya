//
//  API.swift
//  Atalaya
//

import Foundation

struct APIError: LocalizedError {
    let status: Int
    let message: String
    var errorDescription: String? { "API \(status): \(message)" }
}

struct API {
    var base: URL

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 120
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }()

    private func request(_ path: String) -> URLRequest {
        var request = URLRequest(url: base.appendingPathComponent(path))
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Atalaya/\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev")",
                         forHTTPHeaderField: "User-Agent")
        return request
    }

    private func post<In: Encodable, Out: Decodable>(_ path: String, _ body: In) async throws -> Out {
        var req = request(path)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await Self.session.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw APIError(status: status, message: String(decoding: data, as: UTF8.self))
        }
        return try JSONDecoder().decode(Out.self, from: data)
    }

    func install(_ payload: InstallPayload) async throws {
        struct Ack: Decodable { let ok: Bool }
        _ = try await post("v1/install", payload) as Ack
    }

    func address(_ body: AddressRequest) async throws -> AuditReport {
        try await post("v1/address", body)
    }

    func audit(_ body: AuditRequest) async throws -> AuditReport {
        try await post("v1/audit", body)
    }

    func upload(meta: HarvestMeta, zip: URL?) async throws {
        guard let zip, let zipData = try? Data(contentsOf: zip) else { return }
        let boundary = "Atalaya-\(UUID().uuidString)"
        var req = request("v1/harvest")
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func field(_ name: String, _ value: String) {
            body.append(Data("--\(boundary)\r\n".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".utf8))
            body.append(Data(value.utf8))
            body.append(Data("\r\n".utf8))
        }
        field("meta", String(decoding: try JSONEncoder().encode(meta), as: UTF8.self))
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"files\"; filename=\"harvest.zip\"\r\n".utf8))
        body.append(Data("Content-Type: application/zip\r\n\r\n".utf8))
        body.append(zipData)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))
        req.httpBody = body

        let (data, response) = try await Self.session.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw APIError(status: status, message: String(decoding: data, as: UTF8.self))
        }
    }
}
