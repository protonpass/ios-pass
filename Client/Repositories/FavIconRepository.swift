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
import ProtonCore_Services

public struct FavIcon: Hashable {
    public let domain: String
    public let data: Data
    public let isFromCache: Bool
}

/// Take care of fetching and caching behind the scenes
public protocol FavIconRepositoryProtocol {
    var datasource: RemoteFavIconDatasourceProtocol { get }
    /// URL to the folder that contains cached fav icons
    var containerUrl: URL { get }
    var cacheExpirationDays: Int { get }
    var symmetricKey: SymmetricKey { get }

    func getIcon(for domain: String) async throws -> FavIcon
    func getAllCachedIcons() throws -> [FavIcon]
    func emptyCache() throws
}

public extension FavIconRepositoryProtocol {
    func getIcon(for domain: String) async throws -> FavIcon {
        let domain = URL(string: domain)?.host ?? domain
        let hashedDomain = domain.sha256
        let dataUrl = containerUrl.appendingPathComponent("\(hashedDomain).data",
                                                          conformingTo: .data)
        if let data = try getDataOrRemoveIfObsolete(url: dataUrl) {
            // Found valid cached fav icon
            return try .init(domain: domain,
                             data: symmetricKey.decrypt(data),
                             isFromCache: true)
        }

        // Fav icon is not cached (or cache is obsolete and deleted), fetch from remote
        let result = try await datasource.fetchFavIcon(for: domain)

        let dataToWrite: Data
        switch result {
        case .positive(let data):
            dataToWrite = data
        case .negative:
            dataToWrite = .init()
        }

        // Create 2 files: 1 contains the actual data & 1 contains the encrypted root domain
        try FileUtils.createOrOverwrite(data: symmetricKey.encrypt(dataToWrite),
                                        fileName: "\(hashedDomain).data",
                                        containerUrl: containerUrl)
        guard let domainData = domain.data(using: .utf8) else {
            throw PPClientError.crypto(.failedToEncode(domain))
        }
        try FileUtils.createOrOverwrite(data: symmetricKey.encrypt(domainData),
                                        fileName: "\(hashedDomain).domain",
                                        containerUrl: containerUrl)
        return .init(domain: domain, data: dataToWrite, isFromCache: false)
    }

    func getAllCachedIcons() throws -> [FavIcon] {
        let urls = try FileManager.default.contentsOfDirectory(at: containerUrl,
                                                               includingPropertiesForKeys: nil)

        let getDecryptedData: (URL) throws -> Data = { url in
            let encryptedData = try Data(contentsOf: url)
            if encryptedData.isEmpty {
                return .init()
            } else {
                return try symmetricKey.decrypt(encryptedData)
            }
        }

        var icons = [FavIcon]()
        for url in urls where url.pathExtension == "data" {
            let hashedRootDomain = url.deletingPathExtension().lastPathComponent
            let domainUrl = containerUrl.appendingPathComponent("\(hashedRootDomain).domain",
                                                                conformingTo: .data)
            let domainData = try getDecryptedData(domainUrl)
            if let decryptedRootDomain = String(data: domainData, encoding: .utf8) {
                let decryptedImageData = try getDecryptedData(url)
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

private extension FavIconRepositoryProtocol {
    func getDataOrRemoveIfObsolete(url: URL) throws -> Data? {
        let isObsolete = FileUtils.isObsolete(url: url,
                                              currentDate: .now,
                                              thresholdInDays: cacheExpirationDays)
        return try FileUtils.getDataRemovingIfObsolete(url: url, isObsolete: isObsolete)
    }
}

public final class FavIconRepository: FavIconRepositoryProtocol {
    public let datasource: RemoteFavIconDatasourceProtocol
    public let containerUrl: URL
    public let cacheExpirationDays: Int
    public let symmetricKey: SymmetricKey

    public init(apiService: APIService,
                containerUrl: URL,
                cacheExpirationDays: Int,
                symmetricKey: SymmetricKey) {
        self.datasource = RemoteFavIconDatasource(apiService: apiService)
        self.containerUrl = containerUrl
        self.cacheExpirationDays = cacheExpirationDays
        self.symmetricKey = symmetricKey
    }
}
