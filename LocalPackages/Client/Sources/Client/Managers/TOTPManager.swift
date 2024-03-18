//
// TOTPManager.swift
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

import Combine
import Core
import Entities
import Foundation
import PassRustCore

public protocol TOTPManagerProtocol: Sendable {
    var totpData: TOTPData? { get }
    var currentState: CurrentValueSubject<TOTPState, Never> { get }

    func bind(uri: String)
    func generateTotpToken(uri: String) throws -> TOTPData
}

public final class TOTPManager: TOTPManagerProtocol, Sendable {
    private var timer: Timer?
    private let logger: Logger
    private let handler: any TotpHandlerProtocol
    private let generator: any TotpTokenGeneratorProtocol
    private let currentDateProvider: any CurrentDateProviderProtocol
    public let currentState: CurrentValueSubject<Entities.TOTPState, Never> = .init(TOTPState.empty)

    /// The current `URI` whether it's valid or not
    public private(set) var uri = ""

    private var remainTime = 0

    public init(logManager: any LogManagerProtocol,
                currentDateProvider: any CurrentDateProviderProtocol,
                handler: any TotpHandlerProtocol = TotpHandler(),
                generator: any TotpTokenGeneratorProtocol = TotpTokenGenerator()) {
        logger = .init(manager: logManager)
        self.currentDateProvider = currentDateProvider
        self.handler = handler
        self.generator = generator
    }

    deinit {
        timer?.invalidate()
        timer = nil
    }

    public var totpData: TOTPData? {
        if case let .valid(data) = currentState.value {
            return data
        }
        return nil
    }

    public func bind(uri: String) {
        self.uri = uri
        resetTimer()
        currentState.send(.loading)
        guard !uri.isEmpty else {
            currentState.send(.empty)
            return
        }
        refreshData()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                if remainTime > 0 {
                    remainTime -= 1
                } else {
                    refreshData()
                }
            }
        }
        timer?.fire()
    }

    private func resetTimer() {
        timer?.invalidate()
        timer = nil
    }

    func refreshData() {
        do {
            let data = try generateTotpToken(uri: uri)
            remainTime = data.timerData.remaining
            currentState.send(.valid(data))
        } catch {
            logger.error(error)
            currentState.send(.invalid)
            resetTimer()
        }
    }

    public func generateTotpToken(uri: String) throws -> TOTPData {
        let date = currentDateProvider.getCurrentDate()
        let result = try generator.generateToken(uri: uri,
                                                 currentTime: UInt64(date.timeIntervalSince1970))
        let period = Double(handler.getPeriod(totp: result.totp))
        let remainingSeconds = period - date.timeIntervalSince1970.truncatingRemainder(dividingBy: period)
        return .init(code: result.token,
                     timerData: .init(total: Int(period), remaining: Int(remainingSeconds)),
                     label: result.totp.label,
                     issuer: result.totp.issuer)
    }
}
