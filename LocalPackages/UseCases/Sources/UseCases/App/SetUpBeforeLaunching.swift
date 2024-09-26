//
// SetUpBeforeLaunching.swift
// Proton Pass - Created on 03/07/2024.
// Copyright (c) 2024 Proton Technologies AG
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
//

import Client
import Core
import CoreData
import CryptoKit
import Foundation
import UIKit

public enum RootContainer: Sendable {
    case window(UIWindow)
    case viewController(UIViewController?)
}

public protocol SetUpBeforeLaunchingUseCase: Sendable {
    func execute(rootContainer: RootContainer) async throws
}

public extension SetUpBeforeLaunchingUseCase {
    func callAsFunction(rootContainer: RootContainer) async throws {
        try await execute(rootContainer: rootContainer)
    }
}

public final class SetUpBeforeLaunching: SetUpBeforeLaunchingUseCase {
    private let keychain: any KeychainProtocol
    private let databaseService: any DatabaseServiceProtocol
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let userManager: any UserManagerProtocol
    private let prefererencesManager: any PreferencesManagerProtocol
    private let authManager: any AuthManagerProtocol
    private let applyMigration: any ApplyAppMigrationUseCase

    public init(keychain: any KeychainProtocol,
                databaseService: any DatabaseServiceProtocol,
                symmetricKeyProvider: any SymmetricKeyProvider,
                userManager: any UserManagerProtocol,
                prefererencesManager: any PreferencesManagerProtocol,
                authManager: any AuthManagerProtocol,
                applyMigration: any ApplyAppMigrationUseCase) {
        self.keychain = keychain
        self.databaseService = databaseService
        self.symmetricKeyProvider = symmetricKeyProvider
        self.userManager = userManager
        self.prefererencesManager = prefererencesManager
        self.authManager = authManager
        self.applyMigration = applyMigration
    }

    /// Order matters, `UserManager` needs to be set up before `PrefererencesManager`
    /// because `PrefererencesManager` depends on `UserManager`
    public func execute(rootContainer: RootContainer) async throws {
        do {
            try await userManager.setUp()
            try await prefererencesManager.setUp()
            try await applyMigration()
            authManager.setUp()

            await MainActor.run {
                let theme = prefererencesManager.sharedPreferences.unwrapped().theme
                switch rootContainer {
                case let .window(window):
                    window.overrideUserInterfaceStyle = theme.userInterfaceStyle
                case let .viewController(rootViewController):
                    if let rootViewController {
                        rootViewController.overrideUserInterfaceStyle = theme.userInterfaceStyle
                    } else {
                        assertionFailure("rootViewController should not be nil")
                    }
                }
            }
        } catch {
            if error is CryptoKitError || error is DecodingError {
                /*
                   Something is crypgraphically wrong when setting up the app
                  A lot of users encounter `CryptoKitError error 3` when migrating to iOS 18,
                  also probably to a new device.
                  We workaround by rotating the symmetric key (which may be broken after the device migration process)
                 and delete all local data in keychain and databse as a result
                   */

                // Rotate the symmetric key by removing it from keychain
                // and let the SymmetricKeyProvider recreate it
                try? keychain.removeOrError(forKey: kLegacySymmetricKey)
                try? keychain.removeOrError(forKey: kSymmetricKey)
                await (symmetricKeyProvider as? SymmetricKeyProviderImpl)?.clearCache()

                // Other cleanups
                try? keychain.removeOrError(forKey: AuthManager.storageKey)
                try? keychain.removeOrError(forKey: kSharedPreferencesKey)

                let container = databaseService.getContainer()
                let managedObjectContext = container.viewContext
                for entity in container.persistentStoreCoordinator.managedObjectModel.entities {
                    if let name = entity.name {
                        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: name)
                        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                        _ = try? managedObjectContext.execute(batchDeleteRequest)
                    }
                }
            }

            throw error
        }
    }
}
