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
import DIComposition
import Entities
import FactoryKit
import Foundation
import Macro
import Screens

@MainActor
final class ItemHistoryViewModel: ObservableObject {
    @Published private(set) var lastUsedTime: String?
    @Published private(set) var history = [ItemContent]()
    @Published private(set) var files = [ItemFile]()
    @Published private(set) var loading = true

    let item: ItemContent

    private let getItemHistory = dependency(\UseCasesContainer.getItemHistory)
    private let router = dependency(\RouterContainer.mainUIKitSwiftUIRouter)
    @LazyInjected(\ToolingContainer.logger) private var logger
    @LazyInjected(\ServiceContainer.userManager) private var userManager
    @LazyInjected(\RepositoryContainer.itemRepository) private var itemRepository
    @LazyInjected(\RepositoryContainer.shareRepository) private var shareRepository

    @LazyInjected(\RepositoryContainer.fileAttachmentRepository)
    private var fileAttachmentRepository

    private var canLoadMoreItems = true
    private var currentTask: Task<Void, Never>?
    private var lastToken: String?

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

                if let share = try await shareRepository.getShare(shareId: item.shareId),
                   item.item.hasFiles || item.item.hasHadFiles, files.isEmpty {
                    files =
                        try await fileAttachmentRepository.getItemFilesForAllRevisions(userId: userId,
                                                                                       item: item,
                                                                                       share: share)
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
                try await itemRepository.resetHistory(item)
                router.display(element: .infosMessage(#localized("Item history successfully reset"),
                                                      config: .dismissAndRefresh))
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

    func handle(_ error: any Error,
                file: String = #file,
                function: String = #function,
                line: UInt = #line,
                column: UInt = #column) {
        logger.error(error, file: file, function: function, line: line, column: column)
        router.display(element: .displayErrorBanner(error))
    }
}
