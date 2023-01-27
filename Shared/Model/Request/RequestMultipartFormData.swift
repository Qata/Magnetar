//
//  RequestMultipartFormData.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 18/9/2022.
//

import Foundation
import MonadicJSON
import Alamofire

struct RequestMultipartFormData: Codable, Hashable {
    struct Field: Codable, Hashable {
        var name: String
        var value: RequestParameter
        var mimeType: String?
    }
    struct Resolved: Codable, Hashable {
        enum Value: Codable, Hashable {
            case data(Data, mimeType: String, fileName: String? = nil)
            case string(String)
        }
        var name: String
        var value: Field.Value
    }
    var fields: [Field]
    
    func resolve(command: Command, server: Server, formData: Alamofire.MultipartFormData) {
        var ids = command.ids
        fields.map {
            $0.resolve(
                parameter: $0.value,
                command: command,
                server: server,
                ids: &ids
            )
        }
        .forEach { field in
            switch field.value {
            case let .string(string):
                formData.append(string.data(using: .utf8)!, withName: field.name)
            case let .data(data, mimeType, fileName):
                formData.append(data, withName: field.name, fileName: fileName, mimeType: mimeType)
            }
        }
    }

    func resolve(command: Command, server: Server, request: inout URLRequest) {
        var ids = command.ids
        fields.map {
            $0.resolve(
                parameter: $0.value,
                command: command,
                server: server,
                ids: &ids
            )
        }
        .reduce(into: MultipartFormData()) { formData, field in
            switch field.value {
            case let .string(string):
                formData.add(field: field.name, value: string)
            case let .data(data, mimeType, fileName):
                formData.add(field: field.name, data: data, mimeType: mimeType, fileName: fileName)
            }
        }
        .inject(into: &request)
    }
}

extension RequestMultipartFormData.Field: RequestParameterContainer {
    typealias Value = RequestMultipartFormData.Resolved.Value
    typealias Resolved = RequestMultipartFormData.Resolved

    func resolve(string: String) -> Value {
        .string(string)
    }

    func resolve(array: [String], separator: String?) -> Value {
        if let separator = separator {
            return .string(array.joined(separator: separator))
        } else {
            return .data(
                try! JSONEncoder().encode(
                    JSON.array(array.map(JSON.string))
                        .encodable()
                ),
                mimeType: "application/json"
            )
        }
    }

    func resolve(data: Data, name: RequestFileName) -> Value {
        .data(
            data,
            mimeType: mimeType ?? "",
            fileName: name.name
        )
    }
    
    func resolve(bool: Bool) -> Value {
        .string(bool.description)
    }

    func promote(_ value: Value?) -> Resolved {
        .init(
            name: name,
            value: value ?? .string("")
        )
    }
}
