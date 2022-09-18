//
//  MultipartFormDataRequest.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 18/9/2022.
//

import Foundation

struct MultipartFormData {
    private let boundary: String = UUID().uuidString
    private var httpBody = Data()

    mutating func add(field name: String, value: String) {
        httpBody.append(textFormField(named: name, value: value))
    }

    private func textFormField(named name: String, value: String) -> String {
        [
            "--\(boundary)\r\n",
            "Content-Disposition: form-data; name=\"\(name)\"\r\n",
            "Content-Type: text/plain; charset=ISO-8859-1\r\n",
            "Content-Transfer-Encoding: 8bit\r\n",
            "\r\n",
            "\(value)\r\n",
        ].joined()
    }

    mutating func add(field name: String, data: Data, mimeType: String) {
        httpBody.append(dataFormField(named: name, data: data, mimeType: mimeType))
    }

    private func dataFormField(
        named name: String,
        data: Data,
        mimeType: String
    ) -> Data {
        var fieldData = Data()
        fieldData.append("--\(boundary)\r\n")
        fieldData.append("Content-Disposition: form-data; name=\"\(name)\"\r\n")
        fieldData.append("Content-Type: \(mimeType)\r\n")
        fieldData.append("\r\n")
        fieldData.append(data)
        fieldData.append("\r\n")
        return fieldData
    }

    func inject(into request: inout URLRequest) {
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody.appending("--\(boundary)--")
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
    
    func appending(_ string: String) -> Self {
        var mutableCopy = self
        if let data = string.data(using: .utf8) {
            mutableCopy.append(data)
        }
        return mutableCopy
    }
}
