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
    private let handler: any TotpHandlerProtocol
    private let generator: any TotpTokenGeneratorProtocol

    public init(currentDateProvider: any CurrentDateProviderProtocol,
                handler: any TotpHandlerProtocol = TotpHandler(),
                generator: any TotpTokenGeneratorProtocol = TotpTokenGenerator()) {
        self.currentDateProvider = currentDateProvider
        self.handler = handler
        self.generator = generator
    }

    public func execute(uri: String) throws -> TOTPData {
        let date = currentDateProvider.getCurrentDate()
        let result = try generator.generateToken(uri: uri,
                                                 currentTime: UInt64(date.timeIntervalSince1970))
        let period = Double(handler.getPeriod(totp: result.totp))
        let remainingSeconds = period - date.timeIntervalSince1970.truncatingRemainder(dividingBy: period)
        return .init(code: result.token,
                     timerData: .init(total: Int(period), remaining: Int(remainingSeconds)))
    }
}
