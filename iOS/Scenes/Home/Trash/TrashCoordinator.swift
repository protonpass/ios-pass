//
// TrashCoordinator.swift
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

protocol TrashCoordinatorDelegate: AnyObject {
    func trashCoordinatorWantsToShowSidebar()
    func trashCoordinatorWantsToShowLoadingHud()
    func trashCoordinatorWantsToHideLoadingHud()
    func trashCoordinatorWantsToAlertError(_ error: Error)
}

final class TrashCoordinator: Coordinator {
    weak var delegate: TrashCoordinatorDelegate?

    private let userData: UserData
    private let shareRepository: ShareRepositoryProtocol
    private let shareKeysRepository: ShareKeysRepositoryProtocol
    private let itemRevisionRepository: ItemRevisionRepositoryProtocol
    private let publicKeyRepository: PublicKeyRepositoryProtocol

    init(userData: UserData,
         shareRepository: ShareRepositoryProtocol,
         shareKeysRepository: ShareKeysRepositoryProtocol,
         itemRevisionRepository: ItemRevisionRepositoryProtocol,
         publicKeyRepository: PublicKeyRepositoryProtocol) {
        self.userData = userData
        self.shareRepository = shareRepository
        self.shareKeysRepository = shareKeysRepository
        self.itemRevisionRepository = itemRevisionRepository
        self.publicKeyRepository = publicKeyRepository
        super.init()
        self.start()
    }

    private func start() {
        let trashViewModel = TrashViewModel()
        trashViewModel.delegate = self
        trashViewModel.onToggleSidebar = { [unowned self] in
            delegate?.trashCoordinatorWantsToShowSidebar()
        }
        start(with: TrashView(viewModel: trashViewModel))
    }
}

// MARK: - TrashViewModelDelegate
extension TrashCoordinator: BaseViewModelDelegate {
    func viewModelBeginsLoading() {
        delegate?.trashCoordinatorWantsToShowLoadingHud()
    }

    func viewModelStopsLoading() {
        delegate?.trashCoordinatorWantsToHideLoadingHud()
    }

    func viewModelDidFailWithError(_ error: Error) {
        delegate?.trashCoordinatorWantsToAlertError(error)
    }
}
