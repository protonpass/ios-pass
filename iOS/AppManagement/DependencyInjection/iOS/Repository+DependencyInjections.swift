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
import Core
import Factory
import Foundation
import ProtonCoreServices

final class RepositoryContainer: SharedContainer, AutoRegistering {
    static let shared = RepositoryContainer()
    let manager = ContainerManager()

    func autoRegister() {
        manager.defaultScope = .singleton
    }
}

// MARK: - Computed properties

private extension RepositoryContainer {
    var apiService: APIService {
        SharedToolingContainer.shared.apiManager().apiService
    }

    var corruptedSessionEventStream: CorruptedSessionEventStream {
        SharedDataStreamContainer.shared.corruptedSessionEventStream()
    }

    var logManager: LogManagerProtocol {
        SharedToolingContainer.shared.logManager()
    }
}

private extension RepositoryContainer {
    var remoteInviteDatasource: Factory<RemoteInviteDatasourceProtocol> {
        self { RemoteInviteDatasource(apiService: self.apiService,
                                      eventStream: self.corruptedSessionEventStream) }
    }
}

extension RepositoryContainer {
    var reportRepository: Factory<ReportRepositoryProtocol> {
        self { ReportRepository(apiService: self.apiService,
                                userDataProvider: SharedDataContainer.shared.userDataProvider(),
                                logManager: self.logManager) }
    }

    var inviteRepository: Factory<InviteRepositoryProtocol> {
        self { InviteRepository(remoteInviteDatasource: self.remoteInviteDatasource(),
                                logManager: self.logManager) }
    }
}
