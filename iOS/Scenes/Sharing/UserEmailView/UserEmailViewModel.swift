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
    @Published private(set) var canContinue = false
    @Published var goToNextStep = false
    @Published private(set) var vault: SharingVaultData?
    @Published private(set) var recommendationsState: RecommendationsState = .loaded(nil)
    @Published private(set) var isChecking = false

    private var cancellables = Set<AnyCancellable>()
    private let shareInviteRepository = resolve(\SharedRepositoryContainer.shareInviteRepository)
    private let shareInviteService = resolve(\ServiceContainer.shareInviteService)
    private let setShareInvitesUserEmailsAndKeys = resolve(\UseCasesContainer.setShareInvitesUserEmailsAndKeys)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    init() {
        setUp()
    }

    func highlightLastEmail() {
        highlightedEmail = selectedEmails.last
    }

    func appendCurrentEmail() {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else { return }
        guard email.isValidEmail() else {
            router.display(element: .errorMessage(#localized("Invalid email address")))
            return
        }
        if !selectedEmails.contains(email) {
            selectedEmails.append(email)
        }
        self.email = ""
    }

    func toggleHighlight(_ email: String) {
        if highlightedEmail == email {
            highlightedEmail = nil
        } else {
            highlightedEmail = email
        }
    }

    func deselect(_ email: String) {
        selectedEmails.removeAll(where: { $0 == email })
    }

    func saveEmail() {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer {
                isChecking = false
            }
            do {
                isChecking = true
                appendCurrentEmail()
                try await setShareInvitesUserEmailsAndKeys(with: selectedEmails)
                goToNextStep = true
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
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
}

private extension UserEmailViewModel {
    func setUp() {
        $email
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                highlightedEmail = nil
            }
            .store(in: &cancellables)

        $selectedEmails
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selectedEmails in
                guard let self else { return }
                highlightedEmail = nil
                canContinue = !selectedEmails.isEmpty
            }
            .store(in: &cancellables)

        Task { @MainActor [weak self] in
            guard let self else { return }
            vault = shareInviteService.getCurrentSelectedVault()
            do {
                if let shareId = vault?.shareId {
                    recommendationsState = .loading
                    let recommendations = try await shareInviteRepository
                        .getInviteRecommendations(shareId: shareId)
                    recommendationsState = .loaded(recommendations)
                }
            } catch {
                recommendationsState = .loaded(nil)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }
}
