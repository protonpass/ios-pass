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
    var logManager: any LogManagerProtocol {
        SharedToolingContainer.shared.logManager()
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

    var matchUrls: any MatchUrlsUseCase {
        SharedUseCasesContainer.shared.matchUrls()
    }

    var userManager: any UserManagerProtocol {
        SharedServiceContainer.shared.userManager()
    }
}

extension AutoFillUseCaseContainer {
    var mapServiceIdentifierToURL: Factory<any MapASCredentialServiceIdentifierToURLUseCase> {
        self { MapASCredentialServiceIdentifierToURL() }
    }

    var copyTotpTokenAndNotify: Factory<any CopyTotpTokenAndNotifyUseCase> {
        self { CopyTotpTokenAndNotify(logManager: self.logManager,
                                      generateTotpToken: SharedUseCasesContainer.shared.generateTotpToken(),
                                      getSharedPreferences: SharedUseCasesContainer.shared.getSharedPreferences(),
                                      copyToClipboard: SharedUseCasesContainer.shared.copyToClipboard(),
                                      notificationService: SharedServiceContainer.shared.notificationService(),
                                      upgradeChecker: SharedServiceContainer.shared.upgradeChecker()) }
    }

    var fetchCredentials: Factory<any FetchCredentialsUseCase> {
        self { FetchCredentials(symmetricKeyProvider: self.symmetricKeyProvider,
                                accessRepository: self.accessRepository,
                                itemRepository: self.itemRepository,
                                shareRepository: self.shareRepository,
                                matchUrls: self.matchUrls,
                                mapServiceIdentifierToURL: self.mapServiceIdentifierToURL(),
                                logManager: self.logManager) }
    }

    var getItemsForPasskeyCreation: Factory<any GetItemsForPasskeyCreationUseCase> {
        self { GetItemsForPasskeyCreation(symmetricKeyProvider: self.symmetricKeyProvider,
                                          shareRepository: self.shareRepository,
                                          itemRepositiry: self.itemRepository,
                                          accessRepository: self.accessRepository) }
    }

    var createAndAssociatePasskey: Factory<any CreateAndAssociatePasskeyUseCase> {
        self { CreateAndAssociatePasskey(itemRepository: self.itemRepository,
                                         userManager: self.userManager,
                                         createPasskey: self.createPasskey,
                                         updateLastUseTimeAndReindex: self.updateLastUseTimeAndReindex(),
                                         completePasskeyRegistration: self.completePasskeyRegistration()) }
    }

    var generateAuthorizationCredential: Factory<any GenerateAuthorizationCredentialUseCase> {
        self { GenerateAuthorizationCredential(itemRepository: self.itemRepository,
                                               resolvePasskeyChallenge: self.resolvePasskeyChallenge,
                                               totpService: SharedServiceContainer.shared.totpService()) }
    }

    var completePasskeyRegistration: Factory<any CompletePasskeyRegistrationUseCase> {
        self { CompletePasskeyRegistration(addTelemetryEvent: SharedUseCasesContainer.shared.addTelemetryEvent(),
                                           resetFactory: self.resetFactory()) }
    }

    var checkAndAutoFill: Factory<any CheckAndAutoFillUseCase> {
        self { CheckAndAutoFill(credentialProvider: SharedDataContainer.shared.credentialProvider(),
                                userManager: SharedServiceContainer.shared.userManager(),
                                generateAuthorizationCredential: self.generateAuthorizationCredential(),
                                cancelAutoFill: self.cancelAutoFill(),
                                completeAutoFill: self.completeAutoFill()) }
    }

    var autoFillPassword: Factory<any AutoFillPasswordUseCase> {
        self { AutoFillPassword(itemRepository: self.itemRepository,
                                completeAutoFill: self.completeAutoFill()) }
    }

    var autoFillPasskey: Factory<any AutoFillPasskeyUseCase> {
        self { AutoFillPasskey(resolveChallenge: self.resolvePasskeyChallenge,
                               completeAutoFill: self.completeAutoFill()) }
    }

    var associateUrlAndAutoFillPassword: Factory<any AssociateUrlAndAutoFillPasswordUseCase> {
        self { AssociateUrlAndAutoFillPassword(itemRepository: self.itemRepository,
                                               completeAutoFill: self.completeAutoFill()) }
    }

    var cancelAutoFill: Factory<any CancelAutoFillUseCase> {
        self { CancelAutoFill(saveAllLogs: SharedUseCasesContainer.shared.saveAllLogs(),
                              resetFactory: self.resetFactory()) }
    }

    var completeAutoFill: Factory<any CompleteAutoFillUseCase> {
        self { CompleteAutoFill(logManager: self.logManager,
                                telemetryRepository: SharedRepositoryContainer.shared.telemetryEventRepository(),
                                userManager: self.userManager,
                                copyTotpTokenAndNotify: self.copyTotpTokenAndNotify(),
                                updateLastUseTimeAndReindex: self.updateLastUseTimeAndReindex(),
                                resetFactory: self.resetFactory()) }
    }

    var completeConfiguration: Factory<any CompleteConfigurationUseCase> {
        self { CompleteConfiguration(resetFactory: self.resetFactory()) }
    }

    var resetFactory: Factory<any ResetFactoryUseCase> {
        self { ResetFactory() }
    }

    var reindexLoginItem: Factory<any ReindexLoginItemUseCase> {
        self { ReindexLoginItem(manager: SharedServiceContainer.shared.credentialManager(),
                                matchUrls: self.matchUrls,
                                mapServiceIdentifierToUrl: self.mapServiceIdentifierToURL()) }
    }

    var updateLastUseTimeAndReindex: Factory<any UpdateLastUseTimeAndReindexUseCase> {
        self { UpdateLastUseTimeAndReindex(itemRepository: self.itemRepository,
                                           localItemDatasource: SharedRepositoryContainer.shared
                                               .localItemDatasource(),
                                           localShareDatasource: SharedRepositoryContainer.shared
                                               .localShareDatasource(),
                                           reindexLoginItem: self.reindexLoginItem()) }
    }
}
