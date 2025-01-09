//
//
// ItemHistoryViewModel.swift
// Proton Pass - Created on 09/01/2024.
// Copyright (c) 2024 Proton Technologies AG
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
final class ItemHistoryViewModel: ObservableObject, Sendable {
    @Published private(set) var lastUsedTime: String?
    @Published private(set) var history = [ItemContent]()
    @Published private(set) var files = [ItemFile]()
    @Published private(set) var loading = true

    let item: ItemContent

    private let getItemHistory = resolve(\UseCasesContainer.getItemHistory)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    @LazyInjected(\SharedToolingContainer.logger) private var logger
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager
    @LazyInjected(\SharedRepositoryContainer.remoteItemDatasource)
    private var remoteItemDatasource
    @LazyInjected(\SharedRepositoryContainer.fileAttachmentRepository)
    private var fileAttachmentRepository
    @LazyInjected(\SharedUseCasesContainer.getFeatureFlagStatus) private var getFeatureFlagStatus

    private var canLoadMoreItems = true
    private var currentTask: Task<Void, Never>?
    private var lastToken: String?

    var fileAttachmentsEnabled: Bool {
        getFeatureFlagStatus(for: FeatureFlagType.passFileAttachmentsV1)
    }

    init(item: ItemContent) {
        self.item = item
        lastUsedTime = item.lastAutoFilledDate
        setUp()
    }

    deinit {
        currentTask?.cancel()
        currentTask = nil
    }

    func loadItemHistory() {
        guard canLoadMoreItems, currentTask == nil else {
            return
        }
        loading = true

        currentTask = Task { [weak self] in
            guard let self else {
                return
            }
            defer {
                loading = false
                currentTask = nil
            }
            do {
                let userId = try await userManager.getActiveUserId()
                let items = try await getItemHistory(userId: userId,
                                                     shareId: item.shareId,
                                                     itemId: item.itemId,
                                                     lastToken: lastToken)

                if item.item.hasFiles || item.item.hasHadFiles, files.isEmpty {
                    files =
                        try await fileAttachmentRepository.getItemFilesForAllRevisions(userId: userId,
                                                                                       item: item)
                }

                history.append(contentsOf: items.data)
                guard items.lastToken != nil else {
                    canLoadMoreItems = false
                    return
                }
                lastToken = items.lastToken
            } catch {
                handle(error)
            }
        }
    }

    func isCreationRevision(_ currentItem: ItemContent) -> Bool {
        currentItem.item.revision == 1
    }

    func isCurrentRevision(_ currentItem: ItemContent) -> Bool {
        currentItem.item.revision == item.item.revision
    }

    func loadMoreContentIfNeeded(item: ItemContent) {
        guard let lastItem = history.last,
              lastItem.item.revision == item.item.revision else {
            return
        }
        loadItemHistory()
    }

    func resetHistory() {
        loading = true

        Task { [weak self] in
            guard let self else { return }
            defer {
                loading = false
            }

            do {
                let userId = try await userManager.getActiveUserId()
                _ = try await remoteItemDatasource.resetHistory(userId: userId,
                                                                shareId: item.shareId,
                                                                itemId: item.itemId)
                router.display(element: .infosMessage(#localized("Item history successfully reset"),
                                                      config: .init(dismissBeforeShowing: true)))
            } catch {
                handle(error)
            }
        }
    }
}

private extension ItemHistoryViewModel {
    func setUp() {
        loadItemHistory()
    }

    func handle(_ error: any Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }
}
