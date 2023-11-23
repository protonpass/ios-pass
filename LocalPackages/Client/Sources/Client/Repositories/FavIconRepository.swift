//
// FavIconRepository.swift
// Proton Pass - Created on 14/04/2023.
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

import Core
import CryptoKit
import Entities
import Foundation
import ProtonCoreServices

public struct FavIcon: Hashable {
    public let domain: String
    public let data: Data
    public let isFromCache: Bool
}

public protocol FavIconSettings {
    var shouldDisplayFavIcons: Bool { get }
}

/// Take care of fetching and caching behind the scenes
public protocol FavIconRepositoryProtocol {
    var settings: FavIconSettings { get }

    /// Always return `nil` if fav icons are disabled in `Preferences`
    /// Check if the icon is cached on disk and decryptable. Otherwise go fetch a new icon.
    func getIcon(for domain: String) async throws -> FavIcon?

    /// Always return `nil` if fav icons are disabled in `Preferences`
    /// Only get icon from disk. Do not go fetch if icon is not cached.
    func getCachedIcon(for domain: String) -> FavIcon?

    /// For debugging purposes only
    func getAllCachedIcons() throws -> [FavIcon]

    /// Remove cached icons from disk
    func emptyCache() throws
}

public final class FavIconRepository: FavIconRepositoryProtocol, DeinitPrintable {
    deinit { print(deinitMessage) }

    private let datasource: RemoteFavIconDatasourceProtocol
    /// URL to the folder that contains cached fav icons
    private let containerUrl: URL
    private let cacheExpirationDays: Int
    public let settings: FavIconSettings
    private let symmetricKeyProvider: SymmetricKeyProvider

    public init(datasource: RemoteFavIconDatasourceProtocol,
                containerUrl: URL,
                settings: FavIconSettings,
                symmetricKeyProvider: SymmetricKeyProvider,
                cacheExpirationDays: Int = 14) {
        self.datasource = datasource
        self.containerUrl = containerUrl
        self.cacheExpirationDays = cacheExpirationDays
        self.settings = settings
        self.symmetricKeyProvider = symmetricKeyProvider
    }
}

public extension FavIconRepository {
    func getIcon(for domain: String) async throws -> FavIcon? {
        guard settings.shouldDisplayFavIcons else { return nil }
        let symmetricKey = try getSymmetricKey()

        let domain = URL(string: domain)?.host ?? domain
        let hashedDomain = domain.sha256
        let dataUrl = containerUrl.appendingPathComponent("\(hashedDomain).data",
                                                          conformingTo: .data)
        if let encryptedData = try getDataOrRemoveIfObsolete(url: dataUrl),
           let decryptedData = try? symmetricKey.decrypt(encryptedData) {
            return .init(domain: domain, data: decryptedData, isFromCache: true)
        }

        // Fav icon is not cached (or cached but is obsolete/deleted/not decryptable), fetch from remote
        let result = try await datasource.fetchFavIcon(for: domain)

        let dataToWrite: Data = switch result {
        case let .positive(data):
            data
        case .negative:
            .init()
        }

        // Create 2 files: 1 contains the actual data & 1 contains the encrypted root domain
        try FileUtils.createOrOverwrite(data: symmetricKey.encrypt(dataToWrite),
                                        fileName: "\(hashedDomain).data",
                                        containerUrl: containerUrl)
        guard let domainData = domain.data(using: .utf8) else {
            throw PassError.crypto(.failedToEncode(domain))
        }
        try FileUtils.createOrOverwrite(data: symmetricKey.encrypt(domainData),
                                        fileName: "\(hashedDomain).domain",
                                        containerUrl: containerUrl)
        return .init(domain: domain, data: dataToWrite, isFromCache: false)
    }

    func getCachedIcon(for domain: String) -> FavIcon? {
        guard settings.shouldDisplayFavIcons else { return nil }
        let domain = URL(string: domain)?.host ?? domain
        let hashedDomain = domain.sha256
        let dataUrl = containerUrl.appendingPathComponent("\(hashedDomain).data",
                                                          conformingTo: .data)
        if let data = try? getDataOrRemoveIfObsolete(url: dataUrl) {
            return try? .init(domain: domain,
                              data: getSymmetricKey().decrypt(data),
                              isFromCache: true)
        }
        return nil
    }

    func getAllCachedIcons() throws -> [FavIcon] {
        let urls = try FileManager.default.contentsOfDirectory(at: containerUrl,
                                                               includingPropertiesForKeys: nil)

        let getDecryptedData: (URL) throws -> Data? = { [weak self] url in
            guard let self else { return nil }
            let encryptedData = try Data(contentsOf: url)
            if encryptedData.isEmpty {
                return .init()
            } else {
                return try? getSymmetricKey().decrypt(encryptedData)
            }
        }

        var icons = [FavIcon]()
        for url in urls where url.pathExtension == "data" {
            let hashedRootDomain = url.deletingPathExtension().lastPathComponent
            let domainUrl = containerUrl.appendingPathComponent("\(hashedRootDomain).domain",
                                                                conformingTo: .data)

            if let domainData = try getDecryptedData(domainUrl),
               let decryptedRootDomain = String(data: domainData, encoding: .utf8),
               let decryptedImageData = try getDecryptedData(url) {
                icons.append(.init(domain: decryptedRootDomain,
                                   data: decryptedImageData,
                                   isFromCache: true))
            }
        }

        return icons.sorted(by: { $0.domain < $1.domain })
    }

    func emptyCache() throws {
        guard FileManager.default.fileExists(atPath: containerUrl.path) else { return }
        let urls = try FileManager.default.contentsOfDirectory(at: containerUrl,
                                                               includingPropertiesForKeys: nil)
        for url in urls {
            try FileManager.default.removeItem(at: url)
        }
    }
}

private extension FavIconRepository {
    func getSymmetricKey() throws -> SymmetricKey {
        try symmetricKeyProvider.getSymmetricKey()
    }

    func getDataOrRemoveIfObsolete(url: URL) throws -> Data? {
        let isObsolete = FileUtils.isObsolete(url: url,
                                              currentDate: .now,
                                              thresholdInDays: cacheExpirationDays)
        return try FileUtils.getDataRemovingIfObsolete(url: url, isObsolete: isObsolete)
    }
}
