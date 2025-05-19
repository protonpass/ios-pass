//
// CreateSecureLinkViewModel.swift
// Proton Pass - Created on 16/05/2024.
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

import Combine
import Entities
import FactoryKit
import Foundation
import Macro
import UIKit

enum SecureLinkExpiration: Sendable, Hashable, Identifiable {
    case hour(Int)
    case day(Int)

    var id: Int { seconds }

    var title: String {
        switch self {
        case let .hour(hour):
            #localized("%lld hour(s)", hour)
        case let .day(day):
            #localized("%lld day(s)", day)
        }
    }

    var seconds: Int {
        switch self {
        case let .hour(hour):
            hour * 3_600
        case let .day(day):
            day * 24 * 3_600
        }
    }

    static var supportedExpirations: [SecureLinkExpiration] {
        [.hour(1), .day(1), .day(7), .day(14), .day(30)]
    }
}

enum CreateSecureLinkViewModelState {
    case creationWithoutRestriction
    case creationWithRestriction
    case created

    var sheetHeight: CGFloat {
        switch self {
        case .creationWithoutRestriction, .creationWithRestriction:
            310
        case .created:
            450
        }
    }

    static var `default`: Self { .creationWithoutRestriction }
}

@MainActor
final class CreateSecureLinkViewModel: ObservableObject {
    @Published private(set) var link: NewSecureLink?
    @Published var selectedExpiration: SecureLinkExpiration = .day(7)
    @Published var loading = false
    @Published var readCount = 0

    private var state = PassthroughSubject<CreateSecureLinkViewModelState, Never>()
    private var cancellables = Set<AnyCancellable>()

    let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    let createSecureLink = resolve(\UseCasesContainer.createSecureLink)

    let itemContent: ItemContent
    private let share: Share

    weak var sheetPresentation: UISheetPresentationController?

    init(itemContent: ItemContent, share: Share) {
        self.itemContent = itemContent
        self.share = share
        Publishers.CombineLatest($link, $readCount)
            .sink { [weak self] link, count in
                guard let self else { return }
                if link != nil {
                    state.send(.created)
                } else if count == 0 { // swiftlint:disable:this empty_count
                    state.send(.creationWithoutRestriction)
                } else {
                    state.send(.creationWithRestriction)
                }
            }
            .store(in: &cancellables)

        state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                let detent = UISheetPresentationController.Detent.custom { _ in
                    CGFloat(state.sheetHeight)
                }

                sheetPresentation?.animateChanges { [weak self] in
                    guard let self else { return }
                    sheetPresentation?.detents = [detent]
                }
            }
            .store(in: &cancellables)
    }

    func createLink() {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer { loading = false }
            do {
                loading = true
                let result = try await createSecureLink(item: itemContent,
                                                        share: share,
                                                        expirationTime: selectedExpiration.seconds,
                                                        maxReadCount: readCount.nilIfZero)
                link = result
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }
}
