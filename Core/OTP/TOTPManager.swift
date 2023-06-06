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

import OneTimePassword
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
        var tokenGenerator: Generator?
        var username: String?
        var issuer: String?
        var timeInterval: Double = Constants.TotpBase.timer
        
        if uri.contains("otpauth") {
            // "otpauth" as protocol, parse information
            let otpComponents = try URLUtils.OTPParser.parse(urlString: uri)
            if otpComponents.type == .totp,
                let secretData = MF_Base32CodecPass.data(fromBase32String: otpComponents.secret) {
                username = otpComponents.label
                issuer = otpComponents.issuer
                timeInterval = Double(otpComponents.period)
                tokenGenerator = try Generator(factor: .timer(period: timeInterval),
                                               secret: secretData,
                                               algorithm: otpComponents.algorithm.otpAlgorithm,
                                               digits: otpComponents.digits)
            }
        } else if let secretData =
                    MF_Base32CodecPass.data(fromBase32String: uri.spacesRemoved) {
            // Treat the whole string as secret
            tokenGenerator = try Generator(secret: secretData)
        }

        guard let tokenGenerator else {
            throw PPCoreError.totp(.failedToInitializeTOTPObject)
        }
        
        let token = Token(name: username ?? "", issuer: issuer ?? "", generator: tokenGenerator)
        let code = token.currentPassword ?? ""
        let timerData = timeInterval.timerData()
        self.username = username
        self.issuer = issuer
        self.code = code
        self.timerData = timerData
    }
}

public extension OTPComponents.Algorithm {
    var otpAlgorithm: Generator.Algorithm {
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
    private var timer: Timer?
    private let logger: Logger
    private var timeInterval: Double = Constants.TotpBase.timer
    
    @Published public private(set) var state = TOTPState.empty
    
    /// The current `URI` whether it's valid or not
    public private(set) var uri = ""
    
    public init(logManager: LogManager) {
        self.logger = .init(manager: logManager)
    }
    
    deinit {
        timer?.invalidate()
        print(deinitMessage)
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
        guard !uri.isEmpty else {
            state = .empty
            return
        }
        
        do {
            var tokenGenerator: Generator?
            var username: String?
            var issuer: String?
            if uri.contains("otpauth") {
                // "otpauth" as protocol, parse information
                let otpComponents = try URLUtils.OTPParser.parse(urlString: uri)
                if otpComponents.type == .totp,
                   let secretData = MF_Base32CodecPass.data(fromBase32String: otpComponents.secret) {
                    username = otpComponents.label
                    issuer = otpComponents.issuer
                    timeInterval = Double(otpComponents.period)
                    tokenGenerator = try Generator(factor: .timer(period: timeInterval),
                                                   secret: secretData,
                                                   algorithm: otpComponents.algorithm.otpAlgorithm,
                                                   digits: otpComponents.digits)
                }
            } else if let secretData = MF_Base32CodecPass.data(fromBase32String: uri.spacesRemoved) {
                // Treat the whole string as secret
                tokenGenerator = try Generator(secret: secretData)
            }
            
            guard let tokenGenerator else {
                state = .invalid
                return
            }
            
            let token = Token(name: username ?? "",
                              issuer: issuer ?? "",
                              generator: tokenGenerator)
            
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                self?.calculate(token: token, username: username, issuer: issuer)
            }
            timer?.fire()
        } catch {
            logger.error(error)
            state = .invalid
        }
    }
    
    private func calculate(token: Token, username: String?, issuer: String?) {
        let code = token.currentPassword ?? ""
        let timerData = timeInterval.timerData()
        state = .valid(.init(username: username,
                             issuer: issuer,
                             code: code,
                             timerData: timerData))
    }
}

private extension Double {
    func timerData(secondsPast1970: Double = Date().timeIntervalSince1970) -> TOTPTimerData {
        let remainingSeconds = self - secondsPast1970.truncatingRemainder(dividingBy: self)
        return .init(total: self.toInt, remaining: remainingSeconds.toInt)
    }
}

private extension Generator {
    init(secret: Data) throws {
        try self.init(factor: .timer(period: Constants.TotpBase.timer),
                      secret: secret,
                      algorithm: Constants.TotpBase.algo.otpAlgorithm,
                      digits: Constants.TotpBase.digit)
    }
}
