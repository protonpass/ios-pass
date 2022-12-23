//
//  Element.swift
//  pmtest
//
//  Created by denys zelenchuk on 02.10.20.
//

import XCTest

private let app = XCUIApplication()

/**
 Contains actions and waitor functions for different element types.
 */
public struct Element {

    // swiftlint:disable type_name
    public class wait {
        @discardableResult
        public static func forButtonWithIdentifier(_ identifier: String, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) -> XCUIElement {
            let element = app.buttons[identifier]
            XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element \(element.debugDescription) does not exist.", file: file, line: line)
            return element
        }

        @discardableResult
        public static func forImageWithIdentifier(_ identifier: String, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) -> XCUIElement {
            let element = app.images[identifier]
            XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element \(element.debugDescription) does not exist.", file: file, line: line)
            return element
        }

        @discardableResult
        public static func forStaticTextFieldWithIdentifier(_ identifier: String, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) -> XCUIElement {
            let element = app.staticTexts[identifier].firstMatch
            XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element \(element.debugDescription) does not exist.", file: file, line: line)
            return element
        }

        public func forStaticTextFieldWithIdentifier(_ identifier: String, shouldUseFirstMatch: Bool = true, file: StaticString = #filePath, line: UInt = #line, timeout: TimeInterval = 10) -> XCUIElement {
            var element = app.staticTexts[identifier]
            if shouldUseFirstMatch {
                element = element.firstMatch
            }

            XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element \(element.debugDescription) does not exist.", file: file, line: line)
            return element
        }

        @discardableResult
        public static func forTextFieldWithIdentifier(_ identifier: String, shouldUseFirstMatch: Bool = true, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) -> XCUIElement {
            var element = app.textFields[identifier]
            if shouldUseFirstMatch {
                element = element.firstMatch
            }

            XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element \(element.debugDescription) does not exist.", file: file, line: line)
            return element
        }
    }
}
