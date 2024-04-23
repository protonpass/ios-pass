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
    case portonAddress(ProtonAddress)
}

enum GeneralRouterDestination: Hashable {
    case userSharePermission
    case shareSummary
    case historyDetail(currentRevision: ItemContent, pastRevision: ItemContent)
    case darkWebMonitorHome(SecurityWeakness)
    case protonAddressesList([ProtonAddress])
    case aliasesList([AliasMonitorInfo])
    case breachDetail(BreachDetailsInfo)
}

enum GeneralSheetDestination: Identifiable, Hashable {
    case addCustomEmail(CustomEmail?)

    var id: String {
        switch self {
        case .addCustomEmail:
            "addCustomEmail"
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
final class MainNavViewRouter {
    @ViewBuilder
    func navigate(to destination: GeneralRouterDestination) -> some View {
        switch destination {
        case .userSharePermission:
            UserPermissionView()
        case .shareSummary:
            SharingSummaryView()
        case let .historyDetail(currentRevision: currentRevision, pastRevision: pastRevision):
            DetailHistoryView(viewModel: DetailHistoryViewModel(currentRevision: currentRevision,
                                                                pastRevision: pastRevision))
        default:
            EmptyView()
        }
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
            case let .darkWebMonitorHome(securityWeakness):
                if case let .breaches(userBreaches) = securityWeakness {
                    DarkWebMonitorHomeView(viewModel: .init(userBreaches: userBreaches))
                }
            case let .protonAddressesList(items):
                Text(verbatim: "Upcomming screen")
            case let .aliasesList(items):
                Text(verbatim: "Upcomming screen")
            case let .breachDetail(info):
                Text(verbatim: "Upcomming screen")
            }
        }
    }

    func sheetDestinations(sheetDestination: Binding<GeneralSheetDestination?>) -> some View {
        sheet(item: sheetDestination) { destination in
            switch destination {
            case let .addCustomEmail(email):
                AddCustomEmailView(viewModel: .init(email: email))
            }
        }
    }
}

@MainActor
final class PathRouter: ObservableObject {
    @Published var path = NavigationPath()
    @Published var presentedSheet: GeneralSheetDestination?

    init() {}

    func navigate(to destination: GeneralRouterDestination) {
        path.append(destination)
    }

    // periphery:ignore
    func popToRoot() {
        path = NavigationPath()
    }

    // periphery:ignore
    func back(to numberOfScreen: Int = 1) {
        path.removeLast(numberOfScreen)
    }

    func present(sheet: GeneralSheetDestination) {
        presentedSheet = sheet
    }

    // periphery:ignore
    func dismissSheet() {
        presentedSheet = nil
    }
}
