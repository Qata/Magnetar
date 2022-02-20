//
//  Regex.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 18/2/22.
//

public struct Regex: ExpressibleByStringLiteral, CustomStringConvertible {
    public let stringLiteral: String

    public init(stringLiteral: String) {
        self.stringLiteral = stringLiteral
    }

    public var description: String {
        stringLiteral
    }
}

public extension Regex {
    static let url: Self = #"((?:http(?:s)?):\/\/(?:www\.)?[a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,63}\b(?:[-a-zA-Z0-9@:%_\+.~#?&//=]*))"#
}

public extension String {
    func matches(regex: Regex) -> Bool {
        range(of: regex.stringLiteral, options: .regularExpression) != nil
    }
}
