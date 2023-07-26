//
//
// SharingSummaryViewModel.swift
// Proton Pass - Created on 20/07/2023.
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

import Client
import Entities
import Factory
import Foundation

@MainActor
final class SharingSummaryViewModel: ObservableObject, Sendable {
    @Published private(set) var infos: SharingInfos?
    @Published var sendingInvite = false
    @Published var error: Error?

    private var lastTask: Task<Void, Never>?
    private let getShareInviteInfos = resolve(\UseCasesContainer.getCurrentShareInviteInformations)
    private let sendShareInvite = resolve(\UseCasesContainer.sendShareInvite)

    init() {
        setUp()
    }

    deinit {
        print("woot deinit")
    }

    func sendInvite() {
        lastTask?.cancel()
        lastTask = Task { @MainActor [weak self] in
            guard let self, let infos else {
                return
            }
            defer {
                self.sendingInvite = false
                self.lastTask?.cancel()
                self.lastTask = nil
            }
            self.sendingInvite = true
            do {
                if Task.isCancelled {
                    return
                }
                _ = try await self.sendShareInvite(with: infos)
            } catch {
                self.error = error
            }
        }
    }
}

private extension SharingSummaryViewModel {
    func setUp() {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            self.infos = await self.getShareInviteInfos()
        }
    }
}
