//
// SecureLinkDetailViewModel.swift
// Proton Pass - Created on 29/05/2024.
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

import Entities
import FactoryKit
import Foundation
import Macro

struct SecureLinkDetailUiModel: Sendable {
    let secureLinkID: String
    let itemContent: ItemContent
    let url: String
    let expirationTime: Int?
    let readCount: Int?
    let maxReadCount: Int?
    let mode: Mode

    enum Mode: Sendable {
        case create, edit
    }

    var relativeTimeRemaining: String? {
        guard let expirationTime else {
            return nil
        }
        let expirationDate = Date(timeIntervalSince1970: Double(expirationTime))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        let currentDate = Date()
        let relativeTime = formatter.localizedString(for: expirationDate, relativeTo: currentDate)

        return relativeTime
    }

    var readTitle: String {
        switch mode {
        case .create:
            #localized("Can be viewed:")
        case .edit:
            #localized("Opened:")
        }
    }

    var linkActionTitle: String {
        switch mode {
        case .create:
            #localized("View all your secure links")
        case .edit:
            #localized("Remove link")
        }
    }

    var readDescription: String {
        switch mode {
        case .create:
            if let maxReadCount {
                return #localized("%lld time(s)", maxReadCount)
            } else {
                return #localized("Unlimited")
            }
        case .edit:
            let readCountString = if let readCount {
                "\(readCount)"
            } else {
                ""
            }

            let maxReadCountString = if let maxReadCount {
                #localized("%lld time(s)", maxReadCount)
            } else {
                #localized("Unlimited")
            }

            return "\(readCountString)/\(maxReadCountString)"
        }
    }
}

@MainActor
final class SecureLinkDetailViewModel: ObservableObject {
    @Published private(set) var loading = false
    @Published private(set) var finishedDeleting = false

    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let deleteSecureLink = resolve(\UseCasesContainer.deleteSecureLink)

    let uiModel: SecureLinkDetailUiModel

    init(uiModel: SecureLinkDetailUiModel) {
        self.uiModel = uiModel
    }

    func showSecureLinkList() {
        router.present(for: .secureLinks)
    }

    func viewItemDetail() {
        router.present(for: .itemDetail(uiModel.itemContent))
    }

    func deleteLink(link: SecureLinkDetailUiModel) {
        Task { [weak self] in
            guard let self else { return }
            defer { loading = false }
            loading = true
            do {
                try await deleteSecureLink(linkId: link.secureLinkID)
                finishedDeleting = true
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func copyLink() {
        router.action(.copyToClipboard(text: uiModel.url,
                                       message: #localized("Secure link copied")))
    }
}
