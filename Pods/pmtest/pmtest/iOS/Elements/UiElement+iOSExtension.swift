//
//  UiElements+iOSExtension.swift
//  pmtest
//
//  Created by Robert Patchett on 11.10.22.
//

import XCTest

extension UiElement {

    public func focused() -> Bool {
        guard let element = uiElement() else {
            return false
        }
        return element.hasFocus
    }

    public func adjust(to value: String) -> UiElement {
        uiElement()!.adjust(toPickerWheelValue: "\(value)")
        return self
    }

    @discardableResult
    public func pinch(scale: CGFloat, velocity: CGFloat) -> UiElement {
        uiElement()!.pinch(withScale: scale, velocity: velocity)
        return self
    }

    @discardableResult
    public func twoFingerTap(scale: CGFloat, velocity: CGFloat) -> UiElement {
        uiElement()!.twoFingerTap()
        return self
    }

    @discardableResult
    public func typeText(_ text: String) -> UiElement {
        uiElement()!.typeText(text)
        return self
    }
}
