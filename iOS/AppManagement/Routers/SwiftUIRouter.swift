//
// SwiftUIRouter.swift
// Proton Pass - Created on 24/07/2023.
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
import Entities
import SwiftUI

struct ContactsInfos: Hashable {
    let itemId: String
    let shareId: String
    let alias: Alias
    let contacts: PaginatedAliasContacts
}

enum GeneralRouterDestination: Hashable {
    case userSharePermission
    case shareSummary
    case historyDetail(currentRevision: ItemContent, pastRevision: ItemContent)
    case protonAddressesList([ProtonAddress])
    case aliasesList([AliasMonitorInfo])
    case breachDetail(BreachDetailsInfo)
    case monitoredAliases([AliasMonitorInfo], monitored: Bool)
    case darkWebMonitorHome(UserBreaches)
    case contacts(ContactsInfos)
}

enum ValidationEmailType: Hashable {
    case customEmail(CustomEmail?)
    case mailbox(Mailbox?)

    var email: String? {
        switch self {
        case let .customEmail(data):
            data?.email
        case let .mailbox(data):
            data?.email
        }
    }

    var isNotEmpty: Bool {
        switch self {
        case let .customEmail(data):
            data != nil
        case let .mailbox(data):
            data != nil
        }
    }
}

enum GeneralSheetDestination: Identifiable, Hashable {
    case addEmail(ValidationEmailType)
    case breachDetail(Breach)

    var id: String {
        switch self {
        case .addEmail:
            "addEmail"
        case .breachDetail:
            "breachDetail"
        }
    }

    static func == (lhs: GeneralSheetDestination, rhs: GeneralSheetDestination) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@MainActor
extension View {
    var routingProvided: some View {
        navigationDestination(for: GeneralRouterDestination.self) { destination in
            switch destination {
            case .userSharePermission:
                UserPermissionView()
            case .shareSummary:
                SharingSummaryView()
            case let .historyDetail(currentRevision: currentRevision, pastRevision: pastRevision):
                DetailHistoryView(viewModel: DetailHistoryViewModel(currentRevision: currentRevision,
                                                                    pastRevision: pastRevision))
            case let .protonAddressesList(addresses):
                MonitorProtonAddressesView(viewModel: .init(addresses: addresses))
            case let .aliasesList(infos):
                MonitorAliasesView(viewModel: .init(infos: infos))
            case let .breachDetail(info):
                DetailMonitoredItemView(viewModel: .init(infos: info))
            case let .monitoredAliases(infos, monitored):
                MonitorAllAliasesView(infos: infos, monitored: monitored)
            case let .darkWebMonitorHome(breach):
                DarkWebMonitorHomeView(viewModel: .init(userBreaches: breach))
            case let .contacts(infos):
                AliasContactsView(viewModel: .init(infos: infos))
            }
        }
    }

    func sheetDestinations(sheetDestination: Binding<GeneralSheetDestination?>) -> some View {
        sheet(item: sheetDestination) { destination in
            switch destination {
            case let .addEmail(type):
                AddCustomEmailView(viewModel: .init(validationType: type))
            case let .breachDetail(breach):
                BreachDetailView(breach: breach)
            }
        }
    }
}

final class PathRouter: ObservableObject {
    @MainActor @Published var path = NavigationPath()
    @MainActor @Published var presentedSheet: GeneralSheetDestination?

    init() {}

    @MainActor
    func navigate(to destination: GeneralRouterDestination) {
        path.append(destination)
    }

    // periphery:ignore
    @MainActor
    func popToRoot() {
        path = NavigationPath()
    }

    // periphery:ignore
    @MainActor
    func back(to numberOfScreen: Int = 1) {
        path.removeLast(numberOfScreen)
    }

    @MainActor
    func present(sheet: GeneralSheetDestination) {
        presentedSheet = sheet
    }

    // periphery:ignore
    @MainActor
    func dismissSheet() {
        presentedSheet = nil
    }
}
