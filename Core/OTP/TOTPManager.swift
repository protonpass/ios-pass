//
// TotpManager.swift
// Proton Pass - Created on 25/01/2023.
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

import SwiftOTP
import SwiftUI

public enum TOTPState: Equatable {
    case loading
    case empty
    case valid(TOTPData)
    case invalid
}

public struct TOTPTimerData: Hashable {
    public let total: Int
    public let remaining: Int

    public init(total: Int, remaining: Int) {
        self.total = total
        self.remaining = remaining
    }
}

public struct TOTPData: Equatable {
    public let username: String?
    public let issuer: String?
    public let code: String
    public let timerData: TOTPTimerData
}

public extension TOTPData {
    /// Init and calculate TOTP data of the current moment.
    /// Should only be used to quickly get TOTP data from a given URI in AutoFill context.
    init(uri: String) throws {
        let otpComponents = try URLUtils.OTPParser.parse(urlString: uri)
        guard otpComponents.type == .totp else {
            throw PPCoreError.totp(.unsupportedOTP)
        }

        guard let secretData = base32DecodeToData(otpComponents.secret) else {
            throw PPCoreError.totp(.failedToDecodeSecret)
        }

        guard let totp = TOTP(secret: secretData,
                              digits: Int(otpComponents.digits),
                              timeInterval: Int(otpComponents.period),
                              algorithm: otpComponents.algorithm.otpAlgorithm) else {
            throw PPCoreError.totp(.failedToInitializeTOTPObject)
        }
        self.username = otpComponents.label
        self.issuer = otpComponents.issuer
        let secondsPast1970 = Int(Date().timeIntervalSince1970)
        self.code = totp.generate(secondsPast1970: secondsPast1970) ?? ""
        self.timerData = totp.timerData(secondsPast1970: secondsPast1970)
    }
}

public extension OTPComponents.Algorithm {
    var otpAlgorithm: OTPAlgorithm {
        switch self {
        case .sha1:
            return .sha1
        case .sha256:
            return .sha256
        case .sha512:
            return .sha512
        }
    }
}

public final class TOTPManager: DeinitPrintable, ObservableObject {
    deinit {
        timer?.invalidate()
        print(deinitMessage)
    }

    private var timer: Timer?
    private let logger: Logger

    @Published public private(set) var state = TOTPState.empty

    /// The current `URI` whether it's valid or not
    public private(set) var uri = ""

    public init(logManager: LogManager) {
        self.logger = .init(manager: logManager)
    }

    public var totpData: TOTPData? {
        if case .valid(let data) = state {
            return data
        }
        return nil
    }

    public func reset() {
        timer?.invalidate()
        uri = ""
        state = .empty
    }

    public func bind(uri: String) {
        self.uri = uri
        timer?.invalidate()
        state = .loading
        guard !uri.isEmpty else { state = .empty; return }

        do {
            var totp: TOTP?
            var username: String?
            var issuer: String?
            if uri.contains("otpauth") {
                // "otpauth" as protocol, parse information
                let otpComponents = try URLUtils.OTPParser.parse(urlString: uri)
                if otpComponents.type == .totp,
                   let secretData = base32DecodeToData(otpComponents.secret) {
                    username = otpComponents.label
                    issuer = otpComponents.issuer
                    totp = TOTP(secret: secretData,
                                digits: Int(otpComponents.digits),
                                timeInterval: Int(otpComponents.period),
                                algorithm: otpComponents.algorithm.otpAlgorithm)
                }
            } else if let secretData = base32DecodeToData(uri.replacingOccurrences(of: " ", with: "")) {
                // Treat the whole string as secret
                totp = TOTP(secret: secretData,
                            digits: 6,
                            timeInterval: 30,
                            algorithm: .sha1)
            }

            guard let totp else { state = .invalid; return }

            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                self?.calculate(totp: totp, username: username, issuer: issuer)
            }
            timer?.fire()
        } catch {
            logger.error(error)
            state = .invalid
        }
    }

    private func calculate(totp: TOTP, username: String?, issuer: String?) {
        let secondsPast1970 = Int(Date().timeIntervalSince1970)
        let code = totp.generate(secondsPast1970: secondsPast1970) ?? ""
        let timerData = totp.timerData(secondsPast1970: secondsPast1970)
        state = .valid(.init(username: username,
                             issuer: issuer,
                             code: code,
                             timerData: timerData))
    }
}

extension TOTP {
    func timerData(secondsPast1970: Int = Int(Date().timeIntervalSince1970)) -> TOTPTimerData {
        let remainingSeconds = timeInterval - (secondsPast1970 % timeInterval)
        return .init(total: timeInterval, remaining: remainingSeconds)
    }
}
