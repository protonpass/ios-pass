//
// GenerateTotpToken.swift
// Proton Pass - Created on 06/12/2023.
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
//

import Core
import Entities
import Foundation

@preconcurrency import PassRustCore

public final class GenerateTotpToken: GenerateTotpTokenUseCase {
    private let currentDateProvider: any CurrentDateProviderProtocol
    private let parser: any TotpUriParserProtocol
    private let generator: any TotpTokenGeneratorProtocol

    public init(currentDateProvider: any CurrentDateProviderProtocol,
                parser: any TotpUriParserProtocol = TotpUriParser(),
                generator: any TotpTokenGeneratorProtocol = TotpTokenGenerator()) {
        self.currentDateProvider = currentDateProvider
        self.parser = parser
        self.generator = generator
    }

    public func execute(uri: String) throws -> TOTPData {
        let totp: Totp
        if uri.contains("otpauth") {
            totp = try parser.parse(uriString: uri)
        } else {
            // Treat the whole URI as secret
            totp = Totp(label: nil,
                        secret: uri,
                        issuer: nil,
                        algorithm: nil,
                        digits: nil,
                        period: nil)
        }

        let date = currentDateProvider.getCurrentDate()
        let token = try generator.generateCurrentToken(totp: totp,
                                                       currentTime: UInt64(date.timeIntervalSince1970))
        let period = Double(totp.period ?? 30)
        let remainingSeconds = period - date.timeIntervalSince1970.truncatingRemainder(dividingBy: period)
        return .init(code: token,
                     timerData: .init(total: Int(period), remaining: Int(remainingSeconds)))
    }
}
