//
// AutoFillUseCase+DependencyInjections.swift
// Proton Pass - Created on 31/07/2023.
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

import AuthenticationServices
import Client
import Core
import Factory
import Foundation
import UseCases

final class AutoFillUseCaseContainer: SharedContainer, AutoRegistering {
    static let shared = AutoFillUseCaseContainer()
    let manager = ContainerManager()

    func autoRegister() {
        manager.defaultScope = .shared
    }
}

private extension AutoFillUseCaseContainer {
    var preferences: Preferences {
        SharedToolingContainer.shared.preferences()
    }

    var logManager: LogManagerProtocol {
        SharedToolingContainer.shared.logManager()
    }

    var context: ASCredentialProviderExtensionContext {
        AutoFillDataContainer.shared.context()
    }
}

extension AutoFillUseCaseContainer {
    var mapServiceIdentifierToURL: Factory<MapASCredentialServiceIdentifierToURLUseCase> {
        self { MapASCredentialServiceIdentifierToURL() }
    }

    var copyTotpTokenAndNotify: Factory<CopyTotpTokenAndNotifyUseCase> {
        self { CopyTotpTokenAndNotify(preferences: self.preferences,
                                      logManager: self.logManager,
                                      generateTotpToken: SharedUseCasesContainer.shared.generateTotpToken(),
                                      notificationService: SharedServiceContainer.shared.notificationService(),
                                      upgradeChecker: SharedServiceContainer.shared.upgradeChecker()) }
    }

    var cancelAutoFill: Factory<CancelAutoFillUseCase> {
        self { CancelAutoFill(context: self.context,
                              saveAllLogs: SharedUseCasesContainer.shared.saveAllLogs(),
                              resetFactory: self.resetFactory()) }
    }

    var completeAutoFill: Factory<CompleteAutoFillUseCase> {
        self { CompleteAutoFill(context: self.context,
                                logManager: self.logManager,
                                telemetryRepository: SharedRepositoryContainer.shared.telemetryEventRepository(),
                                clipboardManager: SharedServiceContainer.shared.clipboardManager(),
                                copyTotpTokenAndNotify: self.copyTotpTokenAndNotify(),
                                updateLastUseTimeAndReindex: self.updateLastUseTimeAndReindex(),
                                resetFactory: self.resetFactory()) }
    }

    var resetFactory: Factory<ResetFactoryUseCase> {
        self { ResetFactory() }
    }

    var reindexLoginItem: Factory<ReindexLoginItemUseCase> {
        self { ReindexLoginItem(manager: SharedServiceContainer.shared.credentialManager(),
                                mapServiceIdentifierToUrl: self.mapServiceIdentifierToURL()) }
    }

    var updateLastUseTimeAndReindex: Factory<UpdateLastUseTimeAndReindexUseCase> {
        self { UpdateLastUseTimeAndReindex(itemRepository: SharedRepositoryContainer.shared.itemRepository(),
                                           reindexLoginItem: self.reindexLoginItem()) }
    }
}
