//
//  XCUIElement+forceTouchExtension.swift
//  pmtest
//
//  Created by Robert Patchett on 11.10.22.
//

import XCTest

extension XCUIElement {

    open func forceTapElement() {
        if self.isHittable {
            self.tap()
        } else {
            let coordinate: XCUICoordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.0))
            coordinate.tap()
        }
    }

    open func forcePressElement() {
        if self.isHittable {
            self.press(forDuration: 2)
        } else {
            let coordinate: XCUICoordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.0))
            coordinate.press(forDuration: 2)
        }
    }
}
