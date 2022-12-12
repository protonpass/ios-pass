//
//  MainRobot.swift
//  ProtonPass
//
// swiftlint:disable prefixed_toplevel_constant
import pmtest
import ProtonCore_TestingToolkit
import XCTest

private let showLoginButtonLabelText = "Show login"
private let showSignupButtonLabelText = "Show signup"
private let logoutButtonLabelText = "Logout"
private let environmentBlackText = "black"
private let environmentProdText = "prod"
private let environmentPaymentsBlackText = "payments"
private let environmentFosseyBlackText = "fossey"
private let environmentCustomText = "custom"
private let accountExternal = "external"

private let welcomeScreenNoneText = "no screen"
private let welcomeScreenMailText = "mail"
private let welcomeScreenVpnText = "vpn"
private let welcomeScreenDriveText = "drive"
private let welcomeScreenCalendarText = "calendar"

private let closeSwitchText = "LoginViewController.closeButtonSwitch"
private let planSelectorSwitchText = "LoginViewController.planSelectorSwitch"
private let humanVerificationSwitch = "LoginViewController.humanVerificationSwitch"
private let logoutDialogText = "Logout"
private let accountTypeUsername = "username"
private let mailApp = "Login-Mail-AppStoreIAP"
private let hv3LabelText = "v3"

private let deleteAccountButtonLabelText = "Delete account"
private let deleteAccountDeleteButton = "Delete"
private let deleteAccountCancelButton = "Cancel"
private let deleteAccountWarning = "Yes, I want to permanently delete this account and all its data."

public enum SignupInitalMode {
    case `internal`
    case external
}

public enum SignupMode {
    case notAvailable
    case `internal`
    case external
    case both(SignupInitalMode)
}

public enum WelcomeScreenMode {
    case noScreen
    case mail
    case vpn
    case drive
    case calendar
}

public final class MainRobot: CoreElements {
    public func showLogin() -> LoginRobot {
        button(showLoginButtonLabelText).wait().tap()
        return LoginRobot()
    }

//    public func showWelcomeScreen() -> WelcomeRobot {
//        button(showLoginButtonLabelText).wait().tap()
//        return WelcomeRobot()
//    }
//    
    public func showSignup() -> SignupRobot {
        button(showSignupButtonLabelText).tap()
        return SignupRobot()
    }

    public func hv3Tap() -> MainRobot {
        button(hv3LabelText).tap()
        return self
    }

    // TD: to migrate to pmtools
    public func backgroundApp<T: CoreElements>(app: XCUIApplication, robot _: T.Type) -> T {
        XCUIDevice.shared.press(.home)
        let background = app.wait(for: .runningBackground, timeout: 5)
        XCTAssertTrue(background)
        return T()
    }

    public func activateApp<T: CoreElements>(app: XCUIApplication, robot _: T.Type) -> T {
        app.activate()
        XCTAssertTrue(app.state == .runningForeground)
        return T()
    }

    public func activateAppWithSiri<T: CoreElements>(robot _: T.Type) -> T {
        XCUIDevice.shared.siriService.activate(voiceRecognitionText: "Open \(mailApp)")
        return T()
    }

    public func launchApp<T: CoreElements>(app: XCUIApplication, robot _: T.Type) -> T {
        app.launch()
        return T()
    }

    public func terminateApp<T: CoreElements>(app: XCUIApplication, robot _: T.Type) -> T {
        app.terminate()
        return T()
    }

    @discardableResult
    public func changeEnvironmentToCustomIfDomainHereBlackOtherwise(_ dynamicDomainAvailable: Bool) -> MainRobot {
        if dynamicDomainAvailable {
            button(environmentCustomText).tap()
        } else {
            button(environmentBlackText).tap()
        }
        return self
    }

    @discardableResult
    public func changeEnvironmentToProd() -> MainRobot {
        button(environmentProdText).tap()
        return self
    }

    @discardableResult
    public func changeEnvironmentToPaymentsBlack() -> MainRobot {
        button(environmentPaymentsBlackText).tap()
        return self
    }

    @discardableResult
    public func changeEnvironmentToFosseyBlack() -> MainRobot {
        button(environmentFosseyBlackText).tap()
        return self
    }

    public func changeAccountTypeToExternal() -> MainRobot {
        button(accountExternal).tap()
        return self
    }

    public func changeAccountTypeToUsername() -> MainRobot {
        button(accountTypeUsername).tap()
        return self
    }

    @discardableResult
    public func logoutButtonTap() -> MainRobot {
        button(logoutButtonLabelText).wait(time: 180).tap()
        return self
    }

    @discardableResult
    public func changeWelcomeScreenMode(to mode: WelcomeScreenMode) -> MainRobot {
        switch mode {
        case .noScreen: button(welcomeScreenNoneText).tap()
        case .mail: button(welcomeScreenMailText).tap()
        case .vpn: button(welcomeScreenVpnText).tap()
        case .drive: button(welcomeScreenDriveText).tap()
        case .calendar: button(welcomeScreenCalendarText).tap()
        }
        return self
    }

    @discardableResult
    public func closeSwitchTap() -> MainRobot {
        swittch(closeSwitchText).tap()
        return self
    }

    @discardableResult
    public func planSelectorSwitchTap() -> MainRobot {
        swittch(planSelectorSwitchText).tap()
        return self
    }

    @discardableResult
    public func humanVerificationSwitchTap() -> MainRobot {
        swittch(humanVerificationSwitch).tap()
        return self
    }

    @discardableResult
    public func showDeleteAccount() -> MainRobot {
        button(deleteAccountButtonLabelText).wait().tap()
        return self
    }

    public let verify = Verify()
    public let verifyDeleteAccount = VerifyDeleteAccount()

    public class Verify: CoreElements {
        public func buttonLogoutVisible() {
            button(logoutButtonLabelText).wait(time: 90).checkExists()
        }

        public func buttonLogoutIsNotVisible() {
            button(logoutButtonLabelText).wait().checkDoesNotExist()
        }

        public func dialogLogoutShown() -> MainRobot {
            staticText(logoutDialogText).wait(time: 20).checkExists()
            return MainRobot()
        }

        public func buttonLoginVisible() {
            button(showLoginButtonLabelText).wait().checkExists()
        }

        @discardableResult
        public func buttonDeleAccountVisible() -> MainRobot {
            button(deleteAccountButtonLabelText).wait(time: 90).checkExists()
            return MainRobot()
        }
    }

    public class VerifyDeleteAccount: CoreElements {
        public func deleteAccountShown() {
            button(deleteAccountDeleteButton).wait(time: 30).checkExists()
            button(deleteAccountCancelButton).checkExists()
            staticText(deleteAccountWarning).checkExists()
        }
    }
}
