//
//  UIApplication.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 18/2/22.
//

import UIKit
import Algorithms

public extension UIApplication {
    var keyWindow: UIWindow? {
        UIApplication.shared
            .connectedScenes
            .filter(keyPath: \.activationState, ==.foregroundActive)
            .first(ofType: UIWindowScene.self)?
            .windows
            .first(where: \.isKeyWindow)
    }
}
