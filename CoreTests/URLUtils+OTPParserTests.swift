//
// URLUtils+OTPParserTests.swift
// Proton Pass - Created on 18/01/2023.
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

final class URLUtilsPlusOTPParserTests: XCTestCase {
    func testInvalidScheme() {
        let urlString = "https://totp/john.doe%40example.com?secret=somesecret&algorithm=SHA1&digits=8&period=30"
        do {
            let url = try XCTUnwrap(URL(string: urlString))
            _ = try URLUtils.OTPParser.parse(url: url)
            XCTFail("Expect parse failure")
        } catch {
            if let error = error as? URLUtils.OTPParser.Error {
                XCTAssertEqual(error, .invalidScheme("https"))
            } else {
                XCTFail("Expect OTPParser error")
            }
        }
    }

    func testInvalidHost() {
        let urlString = "otpauth://example.com/john.doe%40example.com?secret=somesecret&algorithm=SHA1&digits=8"
        do {
            let url = try XCTUnwrap(URL(string: urlString))
            _ = try URLUtils.OTPParser.parse(url: url)
            XCTFail("Expect parse failure")
        } catch {
            if let error = error as? URLUtils.OTPParser.Error {
                XCTAssertEqual(error, .invalidHost("example.com"))
            } else {
                XCTFail("Expect OTPParser error")
            }
        }
    }

    func testTooManyPaths() {
        let urlString = "otpauth://totp/test/john?secret=somesecret&algorithm=SHA1&digits=8"
        do {
            let url = try XCTUnwrap(URL(string: urlString))
            _ = try URLUtils.OTPParser.parse(url: url)
            XCTFail("Expect parse failure")
        } catch {
            if let error = error as? URLUtils.OTPParser.Error {
                XCTAssertEqual(error, .tooManyPaths)
            } else {
                XCTFail("Expect OTPParser error")
            }
        }
    }

    func testMissingLabel() {
        let urlString = "otpauth://totp/?secret=somesecret&algorithm=SHA1&digits=8"
        do {
            let url = try XCTUnwrap(URL(string: urlString))
            _ = try URLUtils.OTPParser.parse(url: url)
            XCTFail("Expect parse failure")
        } catch {
            if let error = error as? URLUtils.OTPParser.Error {
                XCTAssertEqual(error, .missingLabel)
            } else {
                XCTFail("Expect OTPParser error")
            }
        }
    }

    func testMissingSecret() {
        let urlString = "otpauth://totp/john?algorithm=SHA1&digits=8"
        do {
            let url = try XCTUnwrap(URL(string: urlString))
            _ = try URLUtils.OTPParser.parse(url: url)
            XCTFail("Expect parse failure")
        } catch {
            if let error = error as? URLUtils.OTPParser.Error {
                XCTAssertEqual(error, .missingSecret)
            } else {
                XCTFail("Expect OTPParser error")
            }
        }
    }

    func testParseImplicit() throws {
        let urlString = "otpauth://totp/john.doe%40example.com?secret=somesecret&issuer=ProtonMail"
        let url = try XCTUnwrap(URL(string: urlString))
        let components = try URLUtils.OTPParser.parse(url: url)
        XCTAssertEqual(components.type, .totp)
        XCTAssertEqual(components.label, "john.doe@example.com")
        XCTAssertEqual(components.secret, "somesecret")
        XCTAssertEqual(components.issuer, "ProtonMail")
        XCTAssertEqual(components.algorithm, .sha1)
        XCTAssertEqual(components.digits, 6)
        XCTAssertEqual(components.period, 30)
    }

    func testParseExplicit() throws {
        // swiftlint:disable:next line_length
        let urlString = "otpauth://totp/john.doe%40example.com?secret=somesecret&algorithm=SHA256&digits=8&period=45"
        let url = try XCTUnwrap(URL(string: urlString))
        let components = try URLUtils.OTPParser.parse(url: url)
        XCTAssertEqual(components.type, .totp)
        XCTAssertEqual(components.label, "john.doe@example.com")
        XCTAssertEqual(components.secret, "somesecret")
        XCTAssertNil(components.issuer)
        XCTAssertEqual(components.algorithm, .sha256)
        XCTAssertEqual(components.digits, 8)
        XCTAssertEqual(components.period, 45)
    }

    func testParseExplicitUrlString() throws {
        let urlString = "otpauth://totp/SimpleLogin:john.doe%40gmail.com?secret=ABCDEF&amp;issuer=SimpleLogin"
        let components = try URLUtils.OTPParser.parse(urlString: urlString)
        XCTAssertEqual(components.type, .totp)
        XCTAssertEqual(components.label, "SimpleLogin:john.doe@gmail.com")
        XCTAssertEqual(components.secret, "ABCDEF")
        XCTAssertEqual(components.issuer, "SimpleLogin")
    }
}
