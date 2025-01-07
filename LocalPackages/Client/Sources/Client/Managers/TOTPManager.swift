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

public protocol TOTPManagerProtocol: Sendable {
    var currentState: CurrentValueSubject<TOTPState, Never> { get }

    func bind(uri: String)
}

public extension TOTPManagerProtocol {
    var totpData: TOTPData? {
        if case let .valid(data) = currentState.value {
            return data
        }
        return nil
    }
}

public final class TOTPManager: TOTPManagerProtocol, @unchecked Sendable {
    private var timer: Timer?
    private let logger: Logger
    private let totpService: any TOTPServiceProtocol
    public let currentState: CurrentValueSubject<Entities.TOTPState, Never> = .init(TOTPState.empty)

    /// The current `URI` whether it's valid or not
    public private(set) var uri = ""

    private var remainTime = 0

    public init(logManager: any LogManagerProtocol,
                totpService: any TOTPServiceProtocol) {
        logger = .init(manager: logManager)
        self.totpService = totpService
    }

    deinit {
        timer?.invalidate()
        timer = nil
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
            let data = try totpService.generateTotpToken(uri: uri)
            remainTime = data.timerData.remaining
            currentState.send(.valid(data))
        } catch {
            logger.error(error)
            currentState.send(.invalid)
            resetTimer()
        }
    }
}
