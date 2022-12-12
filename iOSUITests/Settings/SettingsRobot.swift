//
//  MainRobot.swift
//  ProtonPass
//
// swiftlint:disable prefixed_toplevel_constant
import pmtest
import ProtonCore_TestingToolkit
import XCTest

private let telemetryLabelText = "Telemetry"
private let settingsLabelText = "Settings"

final class SettingsRobot: CoreElements {
    let verify = Verify()

    final class Verify: CoreElements {
        @discardableResult
        public func telemetryItemIsDisplayed() -> SettingsRobot {
            staticText(telemetryLabelText).wait().checkExists()
            return SettingsRobot()
        }
    }

    func tapSettingsButton() -> SettingsRobot {
        button(settingsLabelText).wait().tap()
        return self
    }
}
