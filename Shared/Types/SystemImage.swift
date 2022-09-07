//
//  SystemImage.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 9/2/22.
//

import SwiftUI

public enum SystemImage: String, View {
    case arrowClockwise
    case arrowTriangle2Circlepath
    case arrowUp
    case arrowUpArrowDown
    case arrowUpForward
    case checkmark
    case chevronLeft
    case chevronRight
    case cloudFill
    case docBadgePlus
    case docFillBadgePlus
    case exclamationmarkSquareFill
    case line3HorizontalDecreaseCircle
    case line3HorizontalDecreaseCircleFill
    case gear
    case infoCircle
    case linkBadgePlus
    case linkCircle
    case listDash
    case listNumber
    case magnifyingglass
    case pause
    case pauseFill
    case play
    case playFill
    case plus
    case plusCircle
    case serverRack
    case squareAndArrowUp
    case stop
    case stopFill
    case xmark
    case xmarkBin
    case xmarkCircleFill
    
    static var filter: Self {
        .line3HorizontalDecreaseCircle
    }
    
    static var filterFilled: Self {
        .line3HorizontalDecreaseCircleFill
    }

    public var body: Image {
        Image(systemName: systemName)
    }

    public var systemName: String {
        rawValue
            .sfSymbolString
    }
}
