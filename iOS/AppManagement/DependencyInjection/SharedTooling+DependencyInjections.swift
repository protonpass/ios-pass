//
// SharedTooling+DependencyInjection.swift
// Proton Pass - Created on 07/06/2023.
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
import CoreData
import CryptoKit
import Factory
import LocalAuthentication
import ProtonCore_Keymaker
import ProtonCore_Login
import ProtonCore_Services

/// Contain tools shared between main iOS app and extensions
final class SharedToolingContainer: SharedContainer, AutoRegistering {
    static let shared = SharedToolingContainer()
    let manager = ContainerManager()

    private init() {
        let key = "ProtonPass"
        switch Bundle.main.infoDictionary?["MODULE"] as? String {
        case "AUTOFILL_EXTENSION":
            FactoryContext.setArg(PassModule.autoFillExtension, forKey: key)
        case "KEYBOARD_EXTENSION":
            FactoryContext.setArg(PassModule.keyboardExtension, forKey: key)
        default:
            // Default to host app
            break
        }
    }

    func resetCache() {
        manager.reset(scope: .cached)
    }

    func autoRegister() {
        manager.defaultScope = .singleton
    }
}

// MARK: Shared Logging tools

extension SharedToolingContainer {
    var specificLogManager: ParameterFactory<PassModule, LogManager> {
        self { LogManager(module: $0) }
            .unique
    }

    /// Should be made private once transitionned to `Factory`
    /// All objects that want to log should create and hold a new instance of `Logger` with
    /// `resolve(\SharedToolingContainer.logger)`
    var logManager: Factory<LogManagerProtocol> {
        self { LogManager(module: .hostApp) }
            .onArg(PassModule.autoFillExtension) { LogManager(module: .autoFillExtension) }
            .onArg(PassModule.keyboardExtension) { LogManager(module: .keyboardExtension) }
    }

    var logFormatter: Factory<LogFormatterProtocol> {
        self { LogFormatter(format: .txt) }
    }

    /// A `Logger` that has `shared` scope because while all logger instances share a unique `logManager`
    /// each of them should have a different `subsystem` &`category`, so the scope cannot be `unique` or
    /// `singleton`
    var logger: Factory<Logger> {
        self { Logger(manager: self.logManager()) }
            .shared
    }
}

// MARK: Data tools

extension SharedToolingContainer {
    var appData: Factory<AppData> {
        self { AppData() }
    }

    var appVersion: Factory<String> {
        self { "ios-pass@\(Bundle.main.fullAppVersionName)" }
            .onArg(PassModule.autoFillExtension) {
                "ios-pass-autofill-extension@\(Bundle.main.fullAppVersionName)"
            }
    }

    var apiManager: Factory<APIManager> {
        self { APIManager() }
    }
}

// MARK: User centric tools

extension SharedToolingContainer {
    var preferences: Factory<Preferences> {
        self { Preferences() }
    }
}

// MARK: Keychain tools

extension SharedToolingContainer {
    private var baseKeychain: Factory<PPKeychain> {
        self { PPKeychain() }
    }

    var keychain: Factory<KeychainProtocol> {
        self { self.baseKeychain() }
    }

    var settingsProvider: Factory<SettingsProvider> {
        self { self.baseKeychain() }
    }

    var autolocker: Factory<Autolocker> {
        self { Autolocker(lockTimeProvider: self.settingsProvider()) }
    }

    var mainKeyProvider: Factory<MainKeyProvider> {
        self { Keymaker(autolocker: self.autolocker(),
                        keychain: self.baseKeychain()) }
    }
}

// MARK: Local authentication

extension SharedToolingContainer {
    /// Used when users enable biometric authentication. Always fallback to device passcode in this case.
    var localAuthenticationEnablingPolicy: Factory<LAPolicy> {
        self { .deviceOwnerAuthentication }
    }
}

// MARK: Repository tools

extension SharedToolingContainer {
    private var apiService: APIService {
        apiManager().apiService
    }

    var repositoryData: Factory<RepositoryData> {
        self { fatalError("repositoryData not configured") }
            .cached
    }

    var container: NSPersistentContainer {
        repositoryData().container
    }

    var symmetricKey: SymmetricKey {
        repositoryData().symmetricKey
    }

    var userData: UserData {
        repositoryData().userData
    }

    var currentDateProvider: Factory<CurrentDateProviderProtocol> {
        self { CurrentDateProvider() }
    }

    var telemetryScheduler: Factory<TelemetrySchedulerProtocol> {
        self { TelemetryScheduler(currentDateProvider: self.currentDateProvider(),
                                  thresholdProvider: self.preferences()) }
    }
}

// MARK: Repositories

extension SharedToolingContainer {
    var aliasRepository: Factory<AliasRepositoryProtocol> {
        self { AliasRepository(remoteAliasDatasouce: RemoteAliasDatasource(apiService: self.apiService)) }
    }

    var shareKeyRepository: Factory<ShareKeyRepositoryProtocol> {
        self {
            ShareKeyRepository(localShareKeyDatasource: LocalShareKeyDatasource(container: self.container),
                               remoteShareKeyDatasource: RemoteShareKeyDatasource(apiService: self.apiService),
                               logManager: self.logManager(),
                               symmetricKey: self.symmetricKey,
                               userData: self.userData)
        }
    }

    var passKeyManager: Factory<PassKeyManagerProtocol> {
        self {
            PassKeyManager(shareKeyRepository: self.shareKeyRepository(),
                           itemKeyDatasource: RemoteItemKeyDatasource(apiService: self.apiService),
                           logManager: self.logManager(),
                           symmetricKey: self.symmetricKey)
        }
    }

    var shareEventIDRepository: Factory<ShareEventIDRepositoryProtocol> {
        self {
            // swiftformat:disable:next all
            ShareEventIDRepository(
                localShareEventIDDatasource: LocalShareEventIDDatasource(container: self.container),
                remoteShareEventIDDatasource: RemoteShareEventIDDatasource(apiService: self
                    .apiService),
                logManager: self.logManager())
        }
    }

    var itemRepository: Factory<ItemRepositoryProtocol> {
        self {
            // swiftformat:disable:next all
            ItemRepository(
                userData: self.userData,
                symmetricKey: self.symmetricKey,
                localItemDatasoure: LocalItemDatasource(container: self.container),
                remoteItemRevisionDatasource: RemoteItemRevisionDatasource(apiService: self.apiService),
                shareEventIDRepository: self.shareEventIDRepository(),
                passKeyManager: self.passKeyManager(),
                logManager: self.logManager())
        }
    }

    var passPlanRepository: Factory<PassPlanRepositoryProtocol> {
        self {
            PassPlanRepository(localPassPlanDatasource: LocalPassPlanDatasource(container: self.container),
                               remotePassPlanDatasource: RemotePassPlanDatasource(apiService: self.apiService),
                               userId: self.userData.user.ID,
                               logManager: self.logManager())
        }
    }

    var shareRepository: Factory<ShareRepositoryProtocol> {
        self { ShareRepository(symmetricKey: self.symmetricKey,
                               userData: self.userData,
                               localDatasource: LocalShareDatasource(container: self.container),
                               remoteDatasouce: RemoteShareDatasource(apiService: self.apiService),
                               passKeyManager: self.passKeyManager(),
                               logManager: self.logManager()) }
    }

    var telemetryEventRepository: Factory<TelemetryEventRepositoryProtocol> {
        self {
            // swiftformat:disable:next all
            TelemetryEventRepository(
                localTelemetryEventDatasource: LocalTelemetryEventDatasource(container: self.container),
                remoteTelemetryEventDatasource: RemoteTelemetryEventDatasource(apiService: self.apiService),
                remoteUserSettingsDatasource: RemoteUserSettingsDatasource(apiService: self.apiService),
                passPlanRepository: self.passPlanRepository(),
                logManager: self.logManager(),
                scheduler: self.telemetryScheduler(),
                userId: self.userData.user.ID)
        }
    }

    var featureFlagsRepository: Factory<FeatureFlagsRepositoryProtocol> {
        self {
            // swiftformat:disable:next all
            FeatureFlagsRepository(
                localFeatureFlagsDatasource: LocalFeatureFlagsDatasource(container: self.container),
                remoteFeatureFlagsDatasource: RemoteFeatureFlagsDatasource(apiService: self.apiService),
                userId: self.userData.user.ID,
                logManager: self.logManager())
        }
    }

    var favIconRepository: Factory<FavIconRepositoryProtocol> {
        self { FavIconRepository(datasource: RemoteFavIconDatasource(apiService: self.apiService),
                                 containerUrl: URL.favIconsContainerURL(),
                                 settings: self.preferences(),
                                 symmetricKey: self.symmetricKey) }
    }

    var localSearchEntryDatasource: Factory<LocalSearchEntryDatasourceProtocol> {
        self { LocalSearchEntryDatasource(container: self.container) }
    }

    var remoteSyncEventsDatasource: Factory<RemoteSyncEventsDatasourceProtocol> {
        self { RemoteSyncEventsDatasource(apiService: self.apiService) }
    }

    var upgradeChecker: ParameterFactory<LimitationCounterProtocol, UpgradeCheckerProtocol> {
        self { UpgradeChecker(passPlanRepository: self.passPlanRepository(),
                              counter: $0,
                              totpChecker: self.itemRepository()) }
    }

    var credentialManager: Factory<CredentialManagerProtocol> {
        self { CredentialManager(logManager: self.logManager()) }
    }
}
