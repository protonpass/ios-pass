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
import ProtonCore_Login
import ProtonCore_Services
import SwiftUI

final class CreateVaultViewModel: ObservableObject {
    private let coordinator: MyVaultsCoordinator
    private let apiService: APIService
    private let userData: UserData

    init(coordinator: MyVaultsCoordinator,
         apiService: APIService,
         userData: UserData) {
        self.coordinator = coordinator
        self.apiService = apiService
        self.userData = userData
    }

    func cancelAction() {
        coordinator.dismissTopMostModal()
    }

    func createVault(name: String, note: String) {
        Task {
            do {
                let createVaultEndpoint = try CreateVaultEndpoint(credential: userData.credential,
                                                                  addressKey: userData.getAddressKey(),
                                                                  name: name,
                                                                  note: note)
                let result = try await apiService.exec(endpoint: createVaultEndpoint)
                print(result)
            } catch {
                print(error)
            }
        }
    }
}

extension CreateVaultViewModel {
    static var preview: CreateVaultViewModel {
        .init(coordinator: .preview,
              apiService: DummyApiService.preview,
              userData: .preview)
    }
}
