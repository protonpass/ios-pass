//
//
// UserEmailViewModel.swift
// Proton Pass - Created on 19/07/2023.
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
import Combine
import Core
import Entities
import Factory
import Foundation
import Macro
import ProtonCoreHumanVerification

enum RecommendationsState: Equatable {
    case loading
    case loaded(InviteRecommendations?)

    var recommendations: InviteRecommendations? {
        if case let .loaded(data) = self {
            return data
        }

        return nil
    }
}

@MainActor
final class UserEmailViewModel: ObservableObject, Sendable {
    @Published var email = ""
    @Published var selectedEmails: [String] = []
    @Published var highlightedEmail: String?
    @Published private(set) var invalidEmails: [String] = []
    @Published private(set) var canContinue = false
    @Published var goToNextStep = false
    @Published private(set) var vault: SharingVaultData?
    @Published private(set) var recommendationsState: RecommendationsState = .loaded(nil)
    @Published private(set) var isChecking = false
    @Published private(set) var isFetchingMore = false

    private var cancellables = Set<AnyCancellable>()
    private let shareInviteRepository = resolve(\SharedRepositoryContainer.shareInviteRepository)
    private let checkAddressesForInvite = resolve(\UseCasesContainer.checkAddressesForInvite)
    private let shareInviteService = resolve(\ServiceContainer.shareInviteService)
    private let setShareInvitesUserEmailsAndKeys = resolve(\UseCasesContainer.setShareInvitesUserEmailsAndKeys)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private var currentTask: Task<Void, Never>?
    private var canFetchMoreEmails = true

    init() {
        setUp()
        updateRecommendations(removingCurrentRecommendations: true)
    }

    func highlightLastEmail() {
        highlightedEmail = selectedEmails.last
    }

    func appendCurrentEmail() -> Bool {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else { return true }
        guard email.isValidEmail() else {
            router.display(element: .errorMessage(#localized("Invalid email address")))
            return false
        }
        if !selectedEmails.contains(email) {
            selectedEmails.append(email)
        }
        self.email = ""
        return true
    }

    func toggleHighlight(_ email: String) {
        if highlightedEmail == email {
            highlightedEmail = nil
        } else {
            highlightedEmail = email
        }
    }

    func deselect(_ email: String) {
        selectedEmails.removeAll { $0 == email }
    }

    func handleSelection(suggestedEmail: String) {
        if selectedEmails.contains(suggestedEmail) {
            deselect(suggestedEmail)
        } else {
            email = ""
            selectedEmails.append(suggestedEmail)
        }
    }

    func `continue`() async -> Bool {
        defer { isChecking = false }
        do {
            isChecking = true
            guard appendCurrentEmail() else { return false }

            guard let vault else {
                throw PassError.sharing(.incompleteInformation)
            }

            let result = try await checkAddressesForInvite(shareId: vault.shareId,
                                                           emails: selectedEmails)
            if case let .invalid(invalidEmails) = result {
                self.invalidEmails = invalidEmails
                let message =
                    #localized("You can't invite people outside of your organization, contact admin for more info.")
                router.display(element: .errorMessage(message))
                return false
            }

            try await setShareInvitesUserEmailsAndKeys(with: selectedEmails)
            highlightedEmail = nil
            goToNextStep = true
            return true
        } catch {
            router.display(element: .displayErrorBanner(error))
            return false
        }
    }

    func customizeVault() {
        if case let .new(vault, itemContent) = vault {
            router.present(for: .customizeNewVault(vault, itemContent))
        }
    }

    func resetShareInviteInformation() {
        shareInviteService.resetShareInviteInformations()
    }

    func updateRecommendations(removingCurrentRecommendations: Bool) {
        guard canFetchMoreEmails else { return }
        currentTask?.cancel()
        currentTask = nil
        currentTask = Task { [weak self] in
            guard let self else { return }
            defer {
                currentTask = nil
                isFetchingMore = false
            }
            do {
                if Task.isCancelled {
                    return
                }
                guard let shareId = vault?.shareId else { return }
                isFetchingMore = true
                if removingCurrentRecommendations {
                    recommendationsState = .loading
                }
                let currentRecommendations = recommendationsState.recommendations
                let query = InviteRecommendationsQuery(lastToken: currentRecommendations?
                    .planRecommendedEmailsNextToken,
                    pageSize: Constants.Utils.defaultPageSize,
                    email: email)
                let recommendations = try await shareInviteRepository
                    .getInviteRecommendations(shareId: shareId, query: query)
                canFetchMoreEmails = recommendations.planRecommendedEmailsNextToken != nil
                if let currentRecommendations, !removingCurrentRecommendations {
                    recommendationsState = .loaded(currentRecommendations.merging(with: recommendations))
                } else {
                    recommendationsState = .loaded(recommendations)
                }
            } catch {
                recommendationsState = .loaded(nil)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }
}

private extension UserEmailViewModel {
    func setUp() {
        $email
            .dropFirst() // Ignore first event when the view model is initialized
            .removeDuplicates()
            .debounce(for: 0.4, scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                canFetchMoreEmails = true
                updateRecommendations(removingCurrentRecommendations: true)
            }
            .store(in: &cancellables)

        Publishers.CombineLatest($email, $selectedEmails)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] email, selectedEmails in
                guard let self else { return }
                highlightedEmail = nil
                canContinue = !email.isEmpty || !selectedEmails.isEmpty
            }
            .store(in: &cancellables)

        shareInviteService.currentSelectedVault
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                vault = shareInviteService.currentSelectedVault.value
            }
            .store(in: &cancellables)

        vault = shareInviteService.currentSelectedVault.value
    }
}
