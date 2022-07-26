//
//  SystemImage.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 9/2/22.
//

import SwiftUI

public enum SystemImage: String, View {
    case squareAndArrowUp
    case chevronLeft
    case chevronRight
    case stopFill
    case playFill
    case pauseFill
    case stop
    case play
    case pause
    case xmark
    case xmarkCircleFill
    case exclamationmarkSquareFill
    case xmarkBin
    case gear
    case listDash
    case listNumber
    case magnifyingglass
    case arrowClockwise
    case linkBadgePlus
    case docFillBadgePlus
    case plus
    case plusCircle
    case infoCircle
    case serverRack
    case arrowUpArrowDown
    case arrowTriangle2Circlepath

    public var body: Image {
        Image(systemName: systemName)
    }

    public var systemName: String {
        rawValue
            .sfSymbolString
    }
}
