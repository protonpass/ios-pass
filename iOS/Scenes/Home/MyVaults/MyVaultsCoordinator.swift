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

import Client
import Core
import ProtonCore_Login
import ProtonCore_Services
import SwiftUI
import UIKit

protocol MyVaultsCoordinatorDelegate: AnyObject {
    func myVautsCoordinatorWantsToShowSidebar()
    func myVautsCoordinatorWantsToShowLoadingHud()
    func myVautsCoordinatorWantsToHideLoadingHud()
    func myVautsCoordinatorWantsToAlertError(_ error: Error)
}

final class MyVaultsCoordinator: Coordinator {
    weak var delegate: MyVaultsCoordinatorDelegate?

    private lazy var myVaultsViewController: UIViewController = {
        let myVaultsView = MyVaultsView(viewModel: .init(coordinator: self))
        return UIHostingController(rootView: myVaultsView)
    }()

    override var root: Presentable { myVaultsViewController }
    let apiService: APIService
    let userData: UserData
    let vaultSelection: VaultSelection

    init(apiService: APIService,
         userData: UserData,
         vaultSelection: VaultSelection) {
        self.apiService = apiService
        self.userData = userData
        self.vaultSelection = vaultSelection
        super.init(router: .init(), navigationType: .newFlow(hideBar: false))
    }

    func showSidebar() {
        delegate?.myVautsCoordinatorWantsToShowSidebar()
    }

    func showCreateItemView() {
        let createItemView = CreateItemView(coordinator: self)
        router.present(UIHostingController(rootView: createItemView), animated: true)
    }

    func showCreateVaultView() {
        let createVaultViewModel = CreateVaultViewModel(apiService: apiService,
                                                        userData: userData)
        createVaultViewModel.delegate = self
        let createVaultView = CreateVaultView(viewModel: createVaultViewModel)
        let createVaultViewController = UIHostingController(rootView: createVaultView)
        if #available(iOS 15.0, *) {
            createVaultViewController.sheetPresentationController?.detents = [.medium()]
        }
        router.present(createVaultViewController, animated: true)
    }

    func showLoadingHud() {
        delegate?.myVautsCoordinatorWantsToShowLoadingHud()
    }

    func hideLoadingHud() {
        delegate?.myVautsCoordinatorWantsToHideLoadingHud()
    }

    func alert(error: Error) {
        delegate?.myVautsCoordinatorWantsToAlertError(error)
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

// MARK: - CreateVaultViewModelDelegate
extension MyVaultsCoordinator: CreateVaultViewModelDelegate {
    func createVaultViewModelBeginsLoading() {
        delegate?.myVautsCoordinatorWantsToShowLoadingHud()
    }

    func createVaultViewModelStopsLoading() {
        delegate?.myVautsCoordinatorWantsToHideLoadingHud()
    }

    func createVaultViewModelWantsToBeDismissed() {
        dismissTopMostModal()
    }

    func createVaultViewModelDidCreateShare(share: PartialShare) {
        dismissTopMostModal()
    }

    func createVaultViewModelFailedToCreateShare(error: Error) {
        delegate?.myVautsCoordinatorWantsToAlertError(error)
    }
}

extension MyVaultsCoordinator {
    /// For preview purposes
    static var preview: MyVaultsCoordinator {
        .init(apiService: DummyApiService.preview,
              userData: .preview,
              vaultSelection: .preview)
    }
}
