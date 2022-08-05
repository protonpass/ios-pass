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

    let apiService: APIService
    let sessionData: SessionData
    let vaultSelection: VaultSelection
    let repository: RepositoryProtocol

    init(apiService: APIService,
         sessionData: SessionData,
         vaultSelection: VaultSelection) {
        self.apiService = apiService
        self.sessionData = sessionData
        self.vaultSelection = vaultSelection

        let localDatasource = LocalDatasource(inMemory: false)
        let credential = sessionData.userData.credential
        let userId = sessionData.userData.user.ID
        let remoteDatasource = RemoteDatasource(authCredential: credential,
                                                apiService: apiService)
        self.repository = Repository(userId: userId,
                                     localDatasource: localDatasource,
                                     remoteDatasource: remoteDatasource)
        super.init()

        self.start(with: MyVaultsView(viewModel: .init(coordinator: self)))
    }

    func showSidebar() {
        delegate?.myVautsCoordinatorWantsToShowSidebar()
    }

    func showCreateItemView() {
        let createItemView = CreateItemView(coordinator: self)
        let createItemViewController = UIHostingController(rootView: createItemView)
        if #available(iOS 15.0, *) {
            createItemViewController.sheetPresentationController?.detents = [.medium()]
        }
        presentViewController(createItemViewController)
    }

    func showCreateVaultView() {
        let createVaultViewModel = CreateVaultViewModel(coordinator: self)
        createVaultViewModel.delegate = self
        let createVaultView = CreateVaultView(viewModel: createVaultViewModel)
        let createVaultViewController = UIHostingController(rootView: createVaultView)
        if #available(iOS 15.0, *) {
            createVaultViewController.sheetPresentationController?.detents = [.medium()]
        }
        presentViewController(createVaultViewController)
    }

    func showCreateLoginView() {
        let createLoginViewModel = CreateLoginViewModel()
        createLoginViewModel.delegate = self
        let createLoginView = CreateLoginView(viewModel: createLoginViewModel)
        presentView(createLoginView)
    }

    func showCreateAliasView() {
        let createAliasViewModel = CreateAliasViewModel()
        createAliasViewModel.delegate = self
        let createAliasView = CreateAliasView(viewModel: createAliasViewModel)
        presentView(createAliasView)
    }

    func showCreateNoteView() {
        let createNoteViewModel = CreateNoteViewModel()
        createNoteViewModel.delegate = self
        let createNoteView = CreateNoteView(viewModel: createNoteViewModel)
        let createNewNoteController = UIHostingController(rootView: createNoteView)
        if #available(iOS 15, *) {
            createNewNoteController.sheetPresentationController?.detents = [.medium()]
        }
        presentViewController(createNewNoteController)
    }

    func handleCreateNewItemOption(_ option: CreateNewItemOption) {
        dismissTopMostViewController(animated: true) { [unowned self] in
            switch option {
            case .login:
                showCreateLoginView()
            case .alias:
                showCreateAliasView()
            case .note:
                showCreateNoteView()

            case .password:
                let viewModel = GeneratePasswordViewModel(coordinator: self)
                let generatePasswordView = GeneratePasswordView(viewModel: viewModel)
                let generatePasswordViewController = UIHostingController(rootView: generatePasswordView)
                if #available(iOS 15, *) {
                    generatePasswordViewController.sheetPresentationController?.detents = [.medium()]
                }
                presentViewController(generatePasswordViewController)
            }
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

    func createVaultViewModelDidCreateShare(share: PartialShare) {
        // Set vaults to empty to trigger refresh
        vaultSelection.update(vaults: [])
        dismissTopMostViewController()
    }

    func createVaultViewModelDidFailWithError(error: Error) {
        delegate?.myVautsCoordinatorWantsToAlertError(error)
    }
}

// MARK: - CreateLoginViewModelDelegate
extension MyVaultsCoordinator: CreateLoginViewModelDelegate {
    func createLoginViewModelBeginsLoading() {
        delegate?.myVautsCoordinatorWantsToShowLoadingHud()
    }

    func createLoginViewModelStopsLoading() {
        delegate?.myVautsCoordinatorWantsToHideLoadingHud()
    }

    func createLoginViewModelDidFailWithError(error: Error) {
        delegate?.myVautsCoordinatorWantsToAlertError(error)
    }
}

// MARK: - CreateAliasViewModelDelegate
extension MyVaultsCoordinator: CreateAliasViewModelDelegate {
    func createAliasViewModelBeginsLoading() {
        delegate?.myVautsCoordinatorWantsToShowLoadingHud()
    }

    func createAliasViewModelStopsLoading() {
        delegate?.myVautsCoordinatorWantsToHideLoadingHud()
    }

    func createAliasViewModelDidFailWithError(error: Error) {
        delegate?.myVautsCoordinatorWantsToAlertError(error)
    }
}

// MARK: - CreateNoteViewModelDelegate
extension MyVaultsCoordinator: CreateNoteViewModelDelegate {
    func createNoteViewModelBeginsLoading() {
        delegate?.myVautsCoordinatorWantsToShowLoadingHud()
    }

    func createNoteViewModelStopsLoading() {
        delegate?.myVautsCoordinatorWantsToHideLoadingHud()
    }

    func createNoteViewModelDidFailWithError(error: Error) {
        delegate?.myVautsCoordinatorWantsToAlertError(error)
    }
}

extension MyVaultsCoordinator {
    /// For preview purposes
    static var preview: MyVaultsCoordinator {
        .init(apiService: DummyApiService.preview,
              sessionData: .preview,
              vaultSelection: .preview)
    }
}
