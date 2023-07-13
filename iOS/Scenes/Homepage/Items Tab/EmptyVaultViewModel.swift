//
// EmptyVaultViewModel.swift
// Proton Pass - Created on 24/06/2023.
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

import Client
import Core

final class EmptyVaultViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published private var creditCardV1 = false

    var supportedItemContentTypes: [ItemContentType] {
        if creditCardV1 {
            return ItemContentType.allCases
        } else {
            return ItemContentType.allCases.filter { $0 != .creditCard }
        }
    }

    init(featureFlagsRepository: FeatureFlagsRepositoryProtocol,
         logManager: LogManagerProtocol) {
        Task { @MainActor in
            do {
                let flags = try await featureFlagsRepository.getFlags()
                creditCardV1 = flags.creditCardV1
            } catch {
                let logger = Logger(manager: logManager)
                logger.error(error)
            }
        }
    }
}
