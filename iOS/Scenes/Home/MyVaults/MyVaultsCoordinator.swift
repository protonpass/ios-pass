//
// MyVaultsCoordinator.swift
// Proton Pass - Created on 07/07/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import Core
import SwiftUI
import UIKit

protocol MyVaultsCoordinatorDelegate: AnyObject {
    func myVautsCoordinatorWantsToShowSidebar()
}

final class MyVaultsCoordinator: Coordinator {
    weak var delegate: MyVaultsCoordinatorDelegate?

    private lazy var myVaultsViewController: UIViewController = {
        let myVaultsView = MyVaultsView(coordinator: self)
        return UIHostingController(rootView: myVaultsView)
    }()

    override var root: Presentable { myVaultsViewController }

    convenience init() {
        self.init(router: .init(), navigationType: .newFlow(hideBar: false))
    }

    func showSidebar() {
        delegate?.myVautsCoordinatorWantsToShowSidebar()
    }

    func showCreateItemView() {
        let createItemView = CreateItemView(coordinator: self)
        router.present(UIHostingController(rootView: createItemView), animated: true)
    }

    func showCreateVaultView() {
        let createVaultView = CreateVaultView(coordinator: self)
        router.present(UIHostingController(rootView: createVaultView), animated: true)
    }

    func dismissTopMostModal() {
        router.toPresentable().presentedViewController?.dismiss(animated: true)
    }

    private func dismissTopMostModalAndPresent(viewController: UIViewController) {
        let present: () -> Void = { [unowned self] in
            self.router.toPresentable().present(viewController, animated: true, completion: nil)
        }

        if let presentedViewController = router.toPresentable().presentedViewController {
            presentedViewController.dismiss(animated: true, completion: present)
        } else {
            present()
        }
    }

    func handleCreateNewItemOption(_ option: CreateNewItemOption) {
        switch option {
        case .newLogin:
            let createLoginView = CreateLoginView(coordinator: self)
            let createLoginViewController = UIHostingController(rootView: createLoginView)
            dismissTopMostModalAndPresent(viewController: createLoginViewController)
        case .newAlias:
            let createAliasView = CreateAliasView(coordinator: self)
            let createAliasViewController = UIHostingController(rootView: createAliasView)
            dismissTopMostModalAndPresent(viewController: createAliasViewController)
        case .newNote:
            let createNoteView = CreateNoteView(coordinator: self)
            let createNewNoteController = UIHostingController(rootView: createNoteView)
            dismissTopMostModalAndPresent(viewController: createNewNoteController)
        case .generatePassword:
            break
        }
    }
}

extension MyVaultsCoordinator {
    /// For preview purposes
    static var preview: MyVaultsCoordinator { .init() }
}
