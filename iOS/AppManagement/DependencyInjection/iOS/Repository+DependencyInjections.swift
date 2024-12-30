//
// Repository+DependencyInjections.swift
// Proton Pass - Created on 28/06/2023.
// Copyright (c) 2023 Proton Technologies AG
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
import Factory
import Foundation

@preconcurrency import ProtonCoreServices

final class RepositoryContainer: SharedContainer, AutoRegistering {
    static let shared = RepositoryContainer()
    let manager = ContainerManager()

    func autoRegister() {
        manager.defaultScope = .singleton
    }
}

// MARK: - Computed properties

private extension RepositoryContainer {
    var apiManager: any APIManagerProtocol {
        SharedToolingContainer.shared.apiManager()
    }

    var userManager: any UserManagerProtocol {
        SharedServiceContainer.shared.userManager()
    }
}

extension RepositoryContainer {
    var reportRepository: Factory<any ReportRepositoryProtocol> {
        self { ReportRepository(apiServicing: self.apiManager,
                                userManager: self.userManager) }
    }

    var extraPasswordRepository: Factory<any ExtraPasswordRepositoryProtocol> {
        self { ExtraPasswordRepository(apiServicing: self.apiManager) }
    }
}
