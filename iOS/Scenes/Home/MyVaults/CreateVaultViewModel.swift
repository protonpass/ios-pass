//
// CreateVaultViewModel.swift
// Proton Pass - Created on 15/07/2022.
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
import Combine
import Core
import ProtonCore_Login
import ProtonCore_Services
import SwiftUI

protocol CreateVaultViewModelDelegate: AnyObject {
    func createVaultViewModelBeginsLoading()
    func createVaultViewModelStopsLoading()
    func createVaultViewModelWantsToBeDismissed()
    func createVaultViewModelDidCreateShare(share: PartialShare)
    func createVaultViewModelFailedToCreateShare(error: Error)
}

final class CreateVaultViewModel: DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    private let coordinator: MyVaultsCoordinator

    private let isLoadingSubject = PassthroughSubject<Bool, Never>()
    private let createdShareSubject = PassthroughSubject<PartialShare, Error>()
    private var cancellables = Set<AnyCancellable>()

    weak var delegate: CreateVaultViewModelDelegate?

    init(coordinator: MyVaultsCoordinator) {
        self.coordinator = coordinator
        self.subscribeToPublishers()
    }

    private func subscribeToPublishers() {
        isLoadingSubject
            .sink { [weak self] isLoading in
                guard let self = self else { return }
                if isLoading {
                    self.delegate?.createVaultViewModelBeginsLoading()
                } else {
                    self.delegate?.createVaultViewModelStopsLoading()
                }
            }
            .store(in: &cancellables)

        createdShareSubject
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.delegate?.createVaultViewModelFailedToCreateShare(error: error)
                }
            } receiveValue: { [weak self] share in
                guard let self = self else { return }
                self.delegate?.createVaultViewModelDidCreateShare(share: share)
            }
            .store(in: &cancellables)
    }

    func cancelAction() {
        delegate?.createVaultViewModelWantsToBeDismissed()
    }

    func createVault(name: String, note: String) {
        Task { @MainActor in
            do {
                isLoadingSubject.send(true)
                let userData = coordinator.sessionData.userData
                let createVaultEndpoint = try CreateVaultEndpoint(credential: userData.credential,
                                                                  addressKey: userData.getAddressKey(),
                                                                  name: name,
                                                                  note: note)
                let response = try await coordinator.apiService.exec(endpoint: createVaultEndpoint)
                isLoadingSubject.send(false)
                createdShareSubject.send(response.share)
                createdShareSubject.send(completion: .finished)
            } catch {
                isLoadingSubject.send(false)
                createdShareSubject.send(completion: .failure(error))
            }
        }
    }
}

extension CreateVaultViewModel {
    static var preview: CreateVaultViewModel {
        .init(coordinator: .preview)
    }
}
