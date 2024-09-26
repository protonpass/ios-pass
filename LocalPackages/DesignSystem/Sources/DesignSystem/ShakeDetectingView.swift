//
// ShakeDetectingView.swift
// Proton Pass - Created on 26/09/2024.
// Copyright (c) 2024 Proton Technologies AG
//
// This file is part of Proton Pass.
//
// Proton Pass is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Pass is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Pass. If not, see https://www.gnu.org/licenses/.
//

import UIKit

/// Attached to another view to provide shake motion detection
/// As shaking is not a `UIGestureRecognizer` so it can't be added via `UIView`'s`addGestureRecognizer(_:)`
class ShakeDetectingView: UIView {
    var onShake: (() -> Void)?

    override func motionEnded(_ motion: UIEvent.EventSubtype,
                              with event: UIEvent?) {
        if motion == .motionShake {
            onShake?()
        }
    }

    override var canBecomeFirstResponder: Bool {
        true
    }

    // Automatically become the first responder when the view is added to the window
    // Otherwise motionEnded callback is not triggered
    override func didMoveToWindow() {
        becomeFirstResponder()
    }
}

public extension UIView {
    func addShakeMotionDetector(_ onShake: (() -> Void)?) {
        let shakeDetectingView = ShakeDetectingView()
        shakeDetectingView.onShake = onShake
        addSubview(shakeDetectingView)
    }
}
