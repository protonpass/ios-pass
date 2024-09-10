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

import Entities
import SwiftUI

enum BreachDetailsInfo: Equatable, Hashable {
    case alias(AliasMonitorInfo)
    case customEmail(CustomEmail)
    case protonAddress(ProtonAddress)

    var isMonitored: Bool {
        switch self {
        case let .alias(aliasInfos):
            !aliasInfos.alias.item.monitoringDisabled
        case let .customEmail(email):
            !email.monitoringDisabled
        case let .protonAddress(address):
            !address.monitoringDisabled
        }
    }
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
}

enum GeneralSheetDestination: Identifiable, Hashable {
    case addCustomEmail(CustomEmail?)
    case breachDetail(Breach)

    var id: String {
        switch self {
        case .addCustomEmail:
            "addCustomEmail"
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
            }
        }
    }

    func sheetDestinations(sheetDestination: Binding<GeneralSheetDestination?>) -> some View {
        sheet(item: sheetDestination) { destination in
            switch destination {
            case let .addCustomEmail(email):
                AddCustomEmailView(viewModel: .init(email: email))
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
