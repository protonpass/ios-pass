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

    var symmetricKeyProvider: any SymmetricKeyProvider {
        SharedDataContainer.shared.symmetricKeyProvider()
    }

    var itemRepository: any ItemRepositoryProtocol {
        SharedRepositoryContainer.shared.itemRepository()
    }

    var shareRepository: any ShareRepositoryProtocol {
        SharedRepositoryContainer.shared.shareRepository()
    }

    var accessRepository: any AccessRepositoryProtocol {
        SharedRepositoryContainer.shared.accessRepository()
    }

    var createPasskey: any CreatePasskeyUseCase {
        SharedUseCasesContainer.shared.createPasskey()
    }

    var resolvePasskeyChallenge: any ResolvePasskeyChallengeUseCase {
        SharedUseCasesContainer.shared.resolvePasskeyChallenge()
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

    var fetchCredentials: Factory<FetchCredentialsUseCase> {
        self { FetchCredentials(symmetricKeyProvider: self.symmetricKeyProvider,
                                accessRepository: self.accessRepository,
                                itemRepository: self.itemRepository,
                                shareRepository: self.shareRepository,
                                mapServiceIdentifierToURL: self.mapServiceIdentifierToURL(),
                                logManager: self.logManager) }
    }

    var getItemsForPasskeyCreation: Factory<GetItemsForPasskeyCreationUseCase> {
        self { GetItemsForPasskeyCreation(symmetricKeyProvider: self.symmetricKeyProvider,
                                          shareRepository: self.shareRepository,
                                          itemRepositiry: self.itemRepository,
                                          accessRepository: self.accessRepository) }
    }

    var createAndAssociatePasskey: Factory<CreateAndAssociatePasskeyUseCase> {
        self { CreateAndAssociatePasskey(itemRepository: self.itemRepository,
                                         createPasskey: self.createPasskey,
                                         updateLastUseTimeAndReindex: self.updateLastUseTimeAndReindex(),
                                         completePasskeyRegistration: self.completePasskeyRegistration()) }
    }

    var generateAuthorizationCredential: Factory<GenerateAuthorizationCredentialUseCase> {
        self { GenerateAuthorizationCredential(itemRepository: self.itemRepository,
                                               resolvePasskeyChallenge: self.resolvePasskeyChallenge) }
    }

    var completePasskeyRegistration: Factory<CompletePasskeyRegistrationUseCase> {
        self { CompletePasskeyRegistration(context: self.context,
                                           resetFactory: self.resetFactory()) }
    }

    var checkAndAutoFill: Factory<CheckAndAutoFillUseCase> {
        self { CheckAndAutoFill(credentialProvider: SharedDataContainer.shared.credentialProvider(),
                                generateAuthorizationCredential: self.generateAuthorizationCredential(),
                                cancelAutoFill: self.cancelAutoFill(),
                                completeAutoFill: self.completeAutoFill(),
                                preferences: self.preferences) }
    }

    var autoFillPassword: Factory<AutoFillPasswordUseCase> {
        self { AutoFillPassword(itemRepository: self.itemRepository,
                                completeAutoFill: self.completeAutoFill()) }
    }

    var autoFillPasskey: Factory<AutoFillPasskeyUseCase> {
        self { AutoFillPasskey(resolveChallenge: self.resolvePasskeyChallenge,
                               completeAutoFill: self.completeAutoFill()) }
    }

    var associateUrlAndAutoFillPassword: Factory<AssociateUrlAndAutoFillPasswordUseCase> {
        self { AssociateUrlAndAutoFillPassword(itemRepository: self.itemRepository,
                                               completeAutoFill: self.completeAutoFill()) }
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
        self { UpdateLastUseTimeAndReindex(itemRepository: self.itemRepository,
                                           reindexLoginItem: self.reindexLoginItem()) }
    }
}
