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

enum GeneralRouterDestination: Hashable {
    case userSharePermission
    case shareSummary
    case historyDetail(currentRevision: ItemContent, pastRevision: ItemContent)
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
            }
        }
    }
}
