//
// SharedFactoryContainer+DependencyInjection.swift
// Proton Pass - Created on 30/06/2026.
// Copyright (c) 2026 Proton Technologies AG
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

import FactoryKit
import Screens
import UseCases

final class SharedFactoryContainer: SharedContainer, AutoRegistering {
    static let shared = SharedFactoryContainer()
    let manager = ContainerManager()

    func autoRegister() {
        manager.defaultScope = .shared
    }
}

extension SharedFactoryContainer {
    var passwordGeneratorViewModelFactory: Factory<PasswordGeneratorViewModel.Factory> {
        self { @MainActor in
            let repositoryContainer = SharedRepositoryContainer.shared
            let useCaseContainer = SharedUseCasesContainer.shared
            return .init(datasource: repositoryContainer.localPasswordPreferencesDatasource(),
                         generatePassword: useCaseContainer.generatePassword(),
                         generateRandomWords: useCaseContainer.generateRandomWords(),
                         generatePassphrase: useCaseContainer.generatePassphrase(),
                         scorePassword: useCaseContainer.scorePassword(),
                         getOrganizationSettings: useCaseContainer.getOrganizationSettings(),
                         passwordHistoryRepository: repositoryContainer.passwordHistoryRepository(),
                         logManager: SharedToolingContainer.shared.logManager())
        }
    }
}
