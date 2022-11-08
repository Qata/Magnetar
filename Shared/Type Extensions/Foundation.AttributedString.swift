//
//  Foundation.AttributedString.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 5/11/2022.
//

import UIKit
import Foundation

extension AttributedString {
    init(html: Data) throws {
        let attributedString = try NSMutableAttributedString(
            data: html,
            options: [
                .documentType: NSAttributedString.DocumentType.html
            ],
            documentAttributes: nil
        )
        #if os(macOS)
        attributedString.setAttributes(
            [
                .foregroundColor: NSColor.label,
            ],
            range: NSRange(location: 0, length: attributedString.length)
        )
        #else
        attributedString.setAttributes(
            [
                .foregroundColor: UIColor.label,
            ],
            range: NSRange(location: 0, length: attributedString.length)
        )
        #endif
        self = try AttributedString(
            attributedString,
            including: \.uiKit
        )
    }
}
