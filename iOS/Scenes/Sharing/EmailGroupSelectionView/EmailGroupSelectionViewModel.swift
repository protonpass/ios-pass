//
//
// EmailGroupSelectionViewModel.swift
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
import FactoryKit
import Foundation
import Macro

enum SuggestionsDisplayType: Int, Hashable {
    case suggestion = 0
    case organisation = 1
}

@MainActor
final class EmailGroupSelectionViewModel: ObservableObject {
    @Published var email = ""
    @Published var selectedRecommendations: [InviteRecommendationType] = []
    @Published var highlightedRecommendation: InviteRecommendationType?
    @Published private(set) var invalidEmails: [String] = []
    @Published private(set) var canContinue = false
    @Published private(set) var element: SharingElementData?
    @Published private(set) var isChecking = false
    @Published private(set) var isFetchingMore = false
    @Published private(set) var loading = false
    @Published var showGroupMembers = false
    @Published var displayType = SuggestionsDisplayType.suggestion
    @Published private(set) var suggestions: [InviteRecommendationType] = []
    @Published private var cachedOrgRecommendations: OrganizationInviteRecommendations?

    private var cancellables = Set<AnyCancellable>()
    private let inviteRepository = resolve(\SharedRepositoryContainer.inviteRepository)
    private let checkAddressesForInvite = resolve(\UseCasesContainer.checkAddressesForInvite)
    private let shareInviteService = resolve(\ServiceContainer.shareInviteService)
    private let setShareInvitesAndKeys = resolve(\UseCasesContainer.setShareInvitesAndKeys)
    private let userManager = resolve(\SharedServiceContainer.userManager)
    @LazyInjected(\SharedRepositoryContainer.accessRepository) private var accessRepository
    @LazyInjected(\SharedRepositoryContainer.groupRepository) private var groupRepository
    @LazyInjected(\SharedUseCasesContainer.getFeatureFlagStatus) var getFeatureFlagStatus

    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private var currentTask: Task<Void, Never>?
    private var cachedGroupInfos: [InviteRecommendationType]?
    private var updateSuggestionTask: Task<Void, Never>?

    var organizationTitle: String? {
        cachedOrgRecommendations?.groupDisplayName
    }

    var canFetchMore: Bool {
        cachedOrgRecommendations?.canFetchMore ?? true
    }

    init() {
        setUp()
    }

    func highlightLast() {
        highlightedRecommendation = selectedRecommendations.last
    }

    func appendCurrentEmail() -> Bool {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else { return true }
        guard email.isValidEmail() else {
            router.display(element: .errorMessage(#localized("Invalid email address")))
            return false
        }
        if !selectedRecommendations.contains(.email(email)) {
            selectedRecommendations.append(.email(email))
        }
        self.email = ""
        return true
    }

    func toggleHighlight(_ recommendation: InviteRecommendationType) {
        if highlightedRecommendation == recommendation {
            highlightedRecommendation = nil
        } else {
            highlightedRecommendation = recommendation
            if recommendation.hasMembers {
                showGroupMembers = !recommendation.isEmail
            }
        }
    }

    func deselect(_ recommendation: InviteRecommendationType) {
        selectedRecommendations.removeAll { $0 == recommendation }
    }

    func handleSelection(_ recommendation: InviteRecommendationType) {
        if selectedRecommendations.contains(recommendation) {
            deselect(recommendation)
        } else {
            email = ""
            selectedRecommendations.append(recommendation)
        }
    }

    func `continue`() async -> Bool {
        defer { isChecking = false }
        do {
            isChecking = true
            guard appendCurrentEmail() else { return false }

            guard let element else {
                throw PassError.sharing(.incompleteInformation)
            }

            let result = try await checkAddressesForInvite(shareId: element.shareId,
                                                           emails: selectedRecommendations.emails)
            if case let .invalid(invalidEmails) = result {
                self.invalidEmails = invalidEmails
                let message =
                    #localized("You can't invite people outside of your organization, contact admin for more info.")
                router.display(element: .errorMessage(message))
                return false
            }

            try await setShareInvitesAndKeys(with: selectedRecommendations)
            highlightedRecommendation = nil
            return true
        } catch {
            router.display(element: .displayErrorBanner(error))
            return false
        }
    }

    func customizeVault() {
        if case let .new(vault, itemContent) = element {
            router.present(for: .customizeNewVault(vault, itemContent))
        }
    }

    func resetShareInviteInformation() {
        shareInviteService.resetShareInviteInformations()
    }

    func loadData() async {
        loading = true
        await fetchGroupsInfos()
        async let fetchSuggestions = fetchSuggestions()
        async let fetchingOrganizationsRecommendation = fetchOrganizationsRecommendation(shouldFetchMore: true)

        let (newSuggestions, _) = await (fetchSuggestions, fetchingOrganizationsRecommendation)
        suggestions = newSuggestions
        loading = false
    }

    func loadMore() {
        guard canFetchMore else {
            return
        }
        currentTask?.cancel()
        currentTask = nil
        currentTask = Task { [weak self] in
            guard let self else { return }
            defer {
                currentTask = nil
            }
            suggestions = await fetchOrganizationsRecommendation(shouldFetchMore: true)
        }
    }
}

private extension EmailGroupSelectionViewModel {
    func setUp() {
        $email
            .dropFirst() // Ignore first event when the view model is initialized
            .removeDuplicates()
            .compactMap(\.self)
            .debounce(for: 0.4, scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                guard let self else { return }
                if !newValue.isEmpty {
                    cachedOrgRecommendations?.reset()
                }
                updateSuggestedContent(fetchMore: true)
            }
            .store(in: &cancellables)

        Publishers.CombineLatest($email, $selectedRecommendations)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] email, _ in
                guard let self else { return }
                highlightedRecommendation = nil
                canContinue = !email.isEmpty || !selectedRecommendations.isEmpty
            }
            .store(in: &cancellables)

        shareInviteService.currentSelectedElement
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selectedElement in
                guard let self else { return }
                element = selectedElement
            }
            .store(in: &cancellables)

        element = shareInviteService.currentSelectedElement.value

        $displayType
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                updateSuggestedContent()
            }
            .store(in: &cancellables)
    }

    func updateSuggestedContent(fetchMore: Bool = false) {
        updateSuggestionTask?.cancel()
        updateSuggestionTask = Task { [weak self] in
            guard let self else { return }
            switch displayType {
            case .organisation:
                suggestions = await fetchOrganizationsRecommendation(shouldFetchMore: fetchMore)
            case .suggestion:
                suggestions = await fetchSuggestions()
            }
        }
    }

    // MARK: - Utils

    func fetchGroupsInfos() async {
        guard getFeatureFlagStatus(for: FeatureFlagType.passGroupSharingV1) else {
            return
        }

        guard let userAccess = accessRepository.access.value,
              userAccess.access.plan.isBusinessUser,
              let userId = try? await userManager.getActiveUserId() else {
            return
        }

        let groupInfos: [InviteRecommendationType]? = try? await groupRepository
            .getGroupsInfos(userId: userId)
            .map { .group($0) }
        cachedGroupInfos = groupInfos
    }

    func fetchSuggestions() async -> [InviteRecommendationType] {
        guard let shareId = element?.shareId else { return [] }

        do {
            let userId = try await userManager.getActiveUserId()
            let content = try await inviteRepository.getSuggestedInvite(userId: userId,
                                                                        shareId: shareId,
                                                                        email: email)
            var invitations: [InviteRecommendationType] = []
            for element in content {
                if element.isGroup,
                   let groupInvite = cachedGroupInfos?.first(where: { element.email == $0.emailAddress }) {
                    invitations.append(groupInvite)
                } else {
                    invitations.append(.email(element.email))
                }
            }
            return invitations
        } catch {
            router.display(element: .displayErrorBanner(error))
            return []
        }
    }

    func fetchOrganizationsRecommendation(shouldFetchMore: Bool) async -> [InviteRecommendationType] {
        guard let shareId = element?.shareId else { return [] }
        defer {
            isFetchingMore = false
        }
        do {
            if canFetchMore, shouldFetchMore {
                isFetchingMore = true
                let query = InviteRecommendationsQuery(lastToken: cachedOrgRecommendations?.nextToken,
                                                       pageSize: Constants.Utils.defaultPageSize,
                                                       email: email)
                if Task.isCancelled {
                    return []
                }
                let userId = try await userManager.getActiveUserId()
                let newRecommendations =
                    try await inviteRepository.getOrganisationInviteRecommendations(userId: userId,
                                                                                    shareId: shareId,
                                                                                    query: query)

                if cachedOrgRecommendations != nil {
                    cachedOrgRecommendations?.merge(with: newRecommendations)
                } else {
                    cachedOrgRecommendations = newRecommendations
                }
            }
            guard let cachedOrgRecommendations else {
                return []
            }
            var recommendation = cachedGroupInfos ?? []
            for entry in cachedOrgRecommendations.entries {
                recommendation.append(.email(entry.email))
            }
            return recommendation.alphabeticallySorted
        } catch {
            router.display(element: .displayErrorBanner(error))
            return []
        }
    }
}

private extension [InviteRecommendationType] {
    var emails: [String] {
        compactMap(\.emailAddress)
    }

    var alphabeticallySorted: [InviteRecommendationType] {
        sorted { $0.name < $1.name }
    }
}
