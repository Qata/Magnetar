//
//  SystemImage.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 9/2/22.
//

import SwiftUI

public enum SystemImage: String, View {
    case stopFill
    case playFill
    case pauseFill
    case stop
    case play
    case pause
    case xmark
    case exclamationmarkSquareFill
    case xmarkBin
    case gear
    case listDash
    case listNumber
    case magnifyingglass
    case arrowClockwise
    case linkBadgePlus
    case docFillBadgePlus

    public var body: Image {
        Image(systemName: systemName)
    }

    public var systemName: String {
        rawValue
            .chunked(by: { !$1.isUppercase }) // Split on camel casing
            .joined(separator: ".")
            .lowercased()
    }
}
