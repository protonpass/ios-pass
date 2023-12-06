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

import Entities
import Foundation

public final class TOTPManager: DeinitPrintable, ObservableObject {
    private var timer: Timer?
    private let logger: Logger
    private let generateTotpToken: GenerateTotpTokenUseCase

    @Published public private(set) var state = TOTPState.empty

    /// The current `URI` whether it's valid or not
    public private(set) var uri = ""

    public init(logManager: LogManagerProtocol,
                generateTotpToken: GenerateTotpTokenUseCase) {
        logger = .init(manager: logManager)
        self.generateTotpToken = generateTotpToken
    }

    deinit {
        timer?.invalidate()
        print(deinitMessage)
    }

    public var totpData: TOTPData? {
        if case let .valid(data) = state {
            return data
        }
        return nil
    }

    public func bind(uri: String) {
        self.uri = uri
        timer?.invalidate()
        state = .loading
        guard !uri.isEmpty else {
            state = .empty
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            do {
                let data = try generateTotpToken(uri: uri)
                state = .valid(data)
            } catch {
                logger.error(error)
                state = .invalid
            }
        }
        timer?.fire()
    }
}
