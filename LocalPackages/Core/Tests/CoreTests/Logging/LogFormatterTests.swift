//
// LogFormatterTests.swift
// Proton Pass - Created on 04/01/2023.
// Copyright (c) 2023 Proton Technologies AG
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

@testable import Core
import XCTest

// swiftlint:disable line_length
final class LogFormatterTests: XCTestCase {
    func testDefaultFormatterWithFatalEntry() {
        let formatter = LogFormatter.default
        let entry = LogEntry(timestamp: 1_672_737_395,
                             subsystem: "me.proton.pass.ios",
                             category: "host_application",
                             level: .fatal,
                             message: "Fatal error occurred",
                             file: "AppDelegate",
                             function: "logIn()",
                             line: 123,
                             column: 456)

        let formattedEntry = formatter.format(entry: entry)
        XCTAssertEqual(formattedEntry,
                       "2023-01-03T09:16:35.0000 | 🔴 FATAL | me.proton.pass.ios | host_application | AppDelegate.logIn():123:456 - Fatal error occurred")
    }

    func testDefaultFormatterWithErrorEntry() {
        let formatter = LogFormatter.default
        let entry = LogEntry(timestamp: 1_672_745_274,
                             subsystem: "me.proton.pass.ios",
                             category: "host_application",
                             level: .error,
                             message: "Failed to sign up",
                             file: "SignUpViewController",
                             function: "signUp()",
                             line: 82,
                             column: 39)

        let formattedEntry = formatter.format(entry: entry)
        XCTAssertEqual(formattedEntry,
                       "2023-01-03T11:27:54.0000 | 🔴 ERROR | me.proton.pass.ios | host_application | SignUpViewController.signUp():82:39 - Failed to sign up")
    }

    func testDefaultFormatterWithWarningEntry() {
        let formatter = LogFormatter.default
        let entry = LogEntry(timestamp: 1_672_732_899,
                             subsystem: "me.proton.pass.ios.autofill",
                             category: "autofill_extension",
                             level: .warning,
                             message: "No credentials found",
                             file: "CredentialsViewController",
                             function: "fetchCredentials()",
                             line: 189,
                             column: 20)

        let formattedEntry = formatter.format(entry: entry)
        XCTAssertEqual(formattedEntry,
                       "2023-01-03T08:01:39.0000 | 🟡 WARNING | me.proton.pass.ios.autofill | autofill_extension | CredentialsViewController.fetchCredentials():189:20 - No credentials found")
    }

    func testDefaultFormatterWithInfoEntry() {
        let formatter = LogFormatter.default
        let entry = LogEntry(timestamp: 1_672_732_899,
                             subsystem: "me.proton.pass.ios.autofill",
                             category: "autofill_extension",
                             level: .info,
                             message: "Autofilled successfully",
                             file: "CredentialsViewController",
                             function: "autoFill()",
                             line: 45,
                             column: 1)

        let formattedEntry = formatter.format(entry: entry)
        XCTAssertEqual(formattedEntry,
                       "2023-01-03T08:01:39.0000 | 🔵 INFO | me.proton.pass.ios.autofill | autofill_extension | CredentialsViewController.autoFill():45:1 - Autofilled successfully")
    }

    func testDefaultFormatterWithTraceEntry() {
        let formatter = LogFormatter.default
        let entry = LogEntry(timestamp: 1_672_732_899,
                             subsystem: "me.proton.mail",
                             category: "mail_composer",
                             level: .trace,
                             message: "Automatically saved email",
                             file: "ComposerViewController",
                             function: "composeEmail()",
                             line: 45,
                             column: 1)

        let formattedEntry = formatter.format(entry: entry)
        XCTAssertEqual(formattedEntry,
                       "2023-01-03T08:01:39.0000 | ⚫ TRACE | me.proton.mail | mail_composer | ComposerViewController.composeEmail():45:1 - Automatically saved email")
    }

    func testDefaultFormatterWithDebugEntry() {
        let formatter = LogFormatter.default
        let entry = LogEntry(timestamp: 1_672_732_899,
                             subsystem: "me.proton.mail",
                             category: "mail_composer",
                             level: .debug,
                             message: "Email content",
                             file: "ComposerViewController",
                             function: "composeEmail()",
                             line: 56,
                             column: 190)

        let formattedEntry = formatter.format(entry: entry)
        XCTAssertEqual(formattedEntry,
                       "2023-01-03T08:01:39.0000 | 🟣 DEBUG | me.proton.mail | mail_composer | ComposerViewController.composeEmail():56:190 - Email content")
    }

    func testStandardHtmlFormatter() {
        let style = LogFormatStyle(subsystemColors: ["me.proton.mail": "#FF6F00"],
                                   categoryColors: ["mail_composer": "#AEEA00"])
        let formatter = LogFormatter(format: .html(style), options: .standard)
        let entry = LogEntry(timestamp: 1_672_732_899,
                             subsystem: "me.proton.mail",
                             category: "mail_composer",
                             level: .debug,
                             message: "Email content",
                             file: "ComposerViewController",
                             function: "composeEmail()",
                             line: 56,
                             column: 190)

        let formattedEntry = formatter.format(entry: entry)
        XCTAssertEqual(formattedEntry,
                       "2023-01-03T08:01:39.0000 | DEBUG | <span style=\"color:#FF6F00\">me.proton.mail</span> | <span style=\"color:#AEEA00\">mail_composer</span> - Email content")
    }

    func testVerboseHtmlFormatter() {
        let style = LogFormatStyle(subsystemColors: ["me.proton.mail": "#FF6F00"],
                                   categoryColors: ["mail_composer": "#AEEA00"])
        let formatter = LogFormatter(format: .html(style))
        let entry = LogEntry(timestamp: 1_672_732_899,
                             subsystem: "me.proton.mail",
                             category: "mail_composer",
                             level: .debug,
                             message: "Email content",
                             file: "ComposerViewController",
                             function: "composeEmail()",
                             line: 56,
                             column: 190)

        let formattedEntry = formatter.format(entry: entry)
        XCTAssertEqual(formattedEntry,
                       "2023-01-03T08:01:39.0000 | 🟣 DEBUG | <span style=\"color:#FF6F00\">me.proton.mail</span> | <span style=\"color:#AEEA00\">mail_composer</span> | ComposerViewController.composeEmail():56:190 - Email content")
    }
}
