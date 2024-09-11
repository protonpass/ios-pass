//
// AutoFillViewModel.swift
// Proton Pass - Created on 11/09/2024.
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

import Core
import Entities
import Factory
import Foundation

@MainActor
class AutoFillViewModel<T: AutoFillCredentials>: ObservableObject {
    @Published private(set) var results: [T] = []
    @Published var selectedUser: PassUser?

    private let onCreate: (LoginCreationInfo) -> Void
    private let onCancel: () -> Void
    private let onLogOut: () -> Void
    private let multiAccountsMappingManager = MultiAccountsMappingManager()

    let users: [PassUser]

    @LazyInjected(\SharedServiceContainer.eventSynchronizer) private var eventSynchronizer
    @LazyInjected(\SharedToolingContainer.logger) var logger
    @LazyInjected(\SharedRouterContainer.mainUIKitSwiftUIRouter) var router

    var planType: Plan.PlanType? {
        selectedUser?.plan.planType
    }

    var shouldAskForUserWhenCreatingNewItem: Bool {
        users.count > 1 && selectedUser == nil
    }

    /// Vautls of all users keeping only the first one of the ones sharing the same `VaultID`
    private var uniqueVaults: [Vault] {
        results
            .flatMap(\.vaults)
            // Make sure most permissive vaults are on top
            // so we only keep the most permissive one after deduplicating
            .sorted(by: { $0.shareRole > $1.shareRole })
            .deduplicate(by: \.id)
    }

    init(onCreate: @escaping (LoginCreationInfo) -> Void,
         onCancel: @escaping () -> Void,
         onLogOut: @escaping () -> Void,
         users: [PassUser]) {
        self.onCreate = onCreate
        self.onCancel = onCancel
        self.onLogOut = onLogOut
        self.users = users
        if users.count == 1 {
            selectedUser = users.first
        }
        multiAccountsMappingManager.add(users)
    }

    // swiftlint:disable unavailable_function
    func getVaults(userId: String) -> [Vault]? {
        fatalError("Must be overridden by subclasses")
    }

    func generateLoginCreationInfo(userId: String, vaults: [Vault]) -> LoginCreationInfo {
        fatalError("Must be overridden by subclasses")
    }

    func isErrorState() -> Bool {
        fatalError("Must be overridden by subclasses")
    }

    func fetchAutoFillCredentials(userId: String) async throws -> T {
        fatalError("Must be overridden by subclasses")
    }

    // swiftlint:enable unavailable_function

    func changeToErrorState(_ error: any Error) {}
    func changeToLoadingState() {}
    func changeToLoadedState() {}
}

// MARK: - Non trivial common operations

extension AutoFillViewModel {
    func sync(ignoreError: Bool) async {
        do {
            var shouldRefreshItems = false
            for user in users {
                let hasNewEvents = try await eventSynchronizer.sync(userId: user.id)
                shouldRefreshItems = shouldRefreshItems || hasNewEvents
            }

            if shouldRefreshItems {
                await fetchItems()
            }
        } catch {
            logger.error(error)
            if !ignoreError {
                changeToErrorState(error)
            }
        }
    }

    func fetchItems() async {
        do {
            if isErrorState() {
                changeToLoadingState()
            }

            var results = [T]()
            for user in users {
                let result = try await fetchAutoFillCredentials(userId: user.id)
                multiAccountsMappingManager.add(result.vaults, userId: result.userId)
                results.append(result)
            }

            self.results = results
            changeToLoadedState()
        } catch {
            logger.error(error)
            changeToErrorState(error)
        }
    }

    func createNewItem(userId: String?) {
        guard let userId = userId ?? selectedUser?.id else {
            assertionFailure("No userID selected to create new item")
            return
        }
        do {
            guard let vaults = getVaults(userId: userId) else {
                throw PassError.vault(.vaultsNotFound(userId: userId))
            }
            onCreate(generateLoginCreationInfo(userId: userId, vaults: vaults))
        } catch {
            handle(error)
        }
    }

    func getVaultId(for item: any ItemIdentifiable) throws -> String {
        try multiAccountsMappingManager.getVaultId(for: item.shareId).object
    }

    func getUser(for item: any ItemIdentifiable) -> PassUser? {
        guard users.count > 1, selectedUser == nil else { return nil }
        do {
            return try multiAccountsMappingManager.getUser(for: item).object
        } catch {
            handle(error)
            return nil
        }
    }

    func getAllObjects<Object: ItemIdentifiable & Hashable>(_ keyPath: KeyPath<T, [Object]>)
        -> [Object] {
        let uniqueShareIds = uniqueVaults.map(\.shareId)
        return results
            .flatMap { $0[keyPath: keyPath] }
            .filter { uniqueShareIds.contains($0.shareId) }
    }
}

// MARK: - Trivial common operations

extension AutoFillViewModel {
    func handleAuthenticationSuccess() {
        logger.info("Local authentication succesful")
    }

    func handleAuthenticationFailure() {
        logger.error("Failed to locally authenticate. Logging out.")
        onLogOut()
    }

    func handleCancel() {
        onCancel()
    }

    func upgrade() {
        router.present(for: .upgradeFlow)
    }

    func handle(_ error: any Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }
}
