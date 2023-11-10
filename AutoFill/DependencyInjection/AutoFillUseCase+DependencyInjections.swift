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
    var copyTotpTokenAndNotify: Factory<CopyTotpTokenAndNotifyUseCase> {
        self { CopyTotpTokenAndNotify(preferences: self.preferences,
                                      logManager: self.logManager,
                                      notificationService: SharedServiceContainer.shared.notificationService()) }
    }

    var cancelAutoFill: Factory<CancelAutoFillUseCase> {
        self { CancelAutoFill(context: self.context,
                              saveAllLogs: SharedUseCasesContainer.shared.saveAllLogs(),
                              resetFactory: self.resetFactory()) }
    }

    var completeAutoFill: Factory<CompleteAutoFillUseCase> {
        self { CompleteAutoFill(context: self.context,
                                logManager: self.logManager,
                                appVersion: SharedToolingContainer.shared.appVersion(),
                                userDataProvider: SharedDataContainer.shared.userDataProvider(),
                                clipboardManager: SharedServiceContainer.shared.clipboardManager(),
                                copyTotpTokenAndNotify: self.copyTotpTokenAndNotify(),
                                updateLastUseTime: self.updateLastUseTime(),
                                databaseService: SharedServiceContainer.shared.databaseService(),
                                resetFactory: self.resetFactory()) }
    }

    var resetFactory: Factory<ResetFactoryUseCase> {
        self { ResetFactory() }
    }

    var makeNetworkRequest: Factory<MakeNetworkRequestUseCase> {
        self { MakeNetworkRequest(apiService: AutoFillDataContainer.shared.apiServiceLite()) }
    }

    var updateLastUseTime: Factory<UpdateLastUseTimeUseCase> {
        self { UpdateLastUseTime(makeNetworkRequest: self.makeNetworkRequest()) }
    }
}
