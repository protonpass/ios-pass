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
import Macro

@MainActor
final class SharingSummaryViewModel: ObservableObject, Sendable {
    @Published private(set) var infos = [SharingInfos]()
    @Published private(set) var sendingInvite = false
    @Published var showContactSupportAlert = false

    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let getShareInviteInfos = resolve(\UseCasesContainer.getCurrentShareInviteInformations)
    private let sendShareInvite = resolve(\UseCasesContainer.sendShareInvite)
    private let accessRepository = resolve(\SharedRepositoryContainer.accessRepository)

    private var lastTask: Task<Void, Never>?
    private var plan: Plan?

    init() {
        setUp()
    }

    var hasSingleInvite: Bool {
        infos.count == 1
    }

    func sendInvite() {
        lastTask?.cancel()
        lastTask = Task { [weak self] in
            guard let self else {
                return
            }
            defer {
                self.sendingInvite = false
                self.lastTask?.cancel()
                self.lastTask = nil
            }
            sendingInvite = true

            do {
                if Task.isCancelled {
                    return
                }
                async let getPlan = accessRepository.getPlan(userId: nil)
                async let sendShareInvite = sendShareInvite(with: infos)

                plan = try await getPlan
                let sharedElement = try await sendShareInvite

                if let baseInfo = infos.first {
                    switch baseInfo.shareElement {
                    case let .vault(sharedVault):
                        // When sharing a created vault, we want to keep the context
                        // by only dismissing the top most sheet (which is share vault sheet)
                        router.present(for: .manageSharedShare(sharedVault, nil, .topMost))

                    case .item:
                        // swiftlint:disable:next todo
                        // TODO: maybe show the manage share screen
                        router.display(element: .successMessage(#localized("Invitation sent"),
                                                                config: .init(dismissBeforeShowing: true)))

                    case .new:
                        // When sharing a new vault from item detail page,
                        // as the item is moved to the new vault, the last item detail sheet is stale
                        // so we dismiss all sheets
                        router.present(for: .manageSharedShare(sharedElement, nil, .all))
                    }
                }
            } catch {
                if plan?.isBusinessUser == true,
                   let apiError = error.asPassApiError,
                   case .resourceLimitExceeded = apiError {
                    showContactSupportAlert = true
                } else {
                    router.display(element: .displayErrorBanner(error))
                }
            }
        }
    }
}

private extension SharingSummaryViewModel {
    func setUp() {
        infos = getShareInviteInfos()
    }
}
