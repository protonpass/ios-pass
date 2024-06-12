//
// HomepageCoordinator+Sharing.swift
// Proton Pass - Created on 10/06/2024.
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

import Foundation

import DesignSystem
import Entities
import SwiftUI

extension HomepageCoordinator {
    func presentSecureLinks(_ links: [SecureLink]?) {
        let view =
            SecureLinkListView(viewModel: .init(links: links))
        let viewController = UIHostingController(rootView: view)
        viewController.setDetentType(.large, parentViewController: rootViewController)

        present(viewController)
    }

    func presentSecureLinkDetail(link: SecureLinkListUIModel) {
//        dismissTopMostViewController { [weak self] in
//            guard let self else { return }
//            let viewModel = CreateSecureLinkViewModel(itemContent: item)
//            let view = CreateSecureLinkView(viewModel: viewModel)

        let uiModel = SecureLinkDetailUiModel(itemContent: link.itemContent,
                                              url: link.url,
                                              expirationTime: link.secureLink.expirationTime,
                                              readCount: link.secureLink.readCount,
                                              maxReadCount: link.secureLink.maxReadCount,
                                              mode: .edit)
        let view = SecureLinkDetailView(viewModel: .init(uiModel: uiModel))
        let viewController = UIHostingController(rootView: view)
        viewController.setDetentType(.custom(420),
                                     parentViewController: rootViewController)
        viewController.sheetPresentationController?.prefersGrabberVisible = true
//            viewModel.sheetPresentation = viewController.sheetPresentationController
        present(viewController)

//        }
    }
}

// let uiModel = SecureLinkDetailUiModel(itemContent: viewModel.itemContent,
//                                      url: link.url,
//                                      expirationTime: link.expirationTime,
//                                      readCount: nil,
//                                      maxReadCount: viewModel.readCount.nilIfZero,
//                                      mode: .create)
// SecureLinkDetailView(viewModel: .init(uiModel: uiModel))
