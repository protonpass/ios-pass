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

import CryptoKit
import ProtonCore_Services

/// Take care of fetching and caching behind the scenes
public protocol FavIconRepositoryProtocol {
    var datasource: RemoteFavIconDatasourceProtocol { get }
    /// URL to the folder that contains cached fav icons
    var containerUrl: URL { get }
    var cacheExpirationDays: Int { get }
    var symmetricKey: SymmetricKey { get }

    /// Return `Data` if any (whether from cache or newly fetched we don't care)
    /// Return `nil` if the fav icon doesn't exist or fetched but encountered a known `FavIconError`
    /// We also don't care
    ///
    /// Throw an error when encounter networking errors or not known errors.
    /// Can not do anything in this case but log the error and silently fail.
    func getFavIconData(for domain: String) async throws -> Data?
}

public extension FavIconRepositoryProtocol {
    func getFavIconData(for domain: String) async throws -> Data? {
        // Try to see if we have a postive cache
        let positiveFileName = try FavIconCacheUtils.positiveFileName(for: domain,
                                                                      with: symmetricKey)
        let positiveFileData = try getDataOrRemoveIfObsolete(fileName: positiveFileName)
        if let positiveFileData {
            if positiveFileData.isEmpty {
                // Should not occur but who knows
                return nil
            }
            return positiveFileData
        }

        // Try to see if we have a negative cache
        let negativeFileName = try FavIconCacheUtils.negativeFileName(for: domain,
                                                                      with: symmetricKey)
        let negativeFileData = try getDataOrRemoveIfObsolete(fileName: negativeFileName)
        if negativeFileData != nil {
            return nil
        }

        // Nothing is cached (or cache is obsolete and deleted), fetch from remote
        let result = try await datasource.fetchFavIcon(for: domain)

        switch result {
        case .positive(let data):
            try FavIconCacheUtils.cache(data: data,
                                        fileName: positiveFileName,
                                        containerUrl: containerUrl)
            return data
        case .negative:
            try FavIconCacheUtils.cache(data: nil,
                                        fileName: negativeFileName,
                                        containerUrl: containerUrl)
            return nil
        }
    }
}

private extension FavIconRepositoryProtocol {
    func getDataOrRemoveIfObsolete(fileName: String) throws -> Data? {
        let isObsolete = FavIconCacheUtils.isObsolete(fileName: fileName,
                                                      containerUrl: containerUrl,
                                                      currentDate: .now,
                                                      thresholdInDays: cacheExpirationDays)

        let fileData = try FavIconCacheUtils.getDataRemovingIfObsolete(fileName: fileName,
                                                                       containerUrl: containerUrl,
                                                                       isObsolete: isObsolete)
        return fileData
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

enum FavIconCacheUtils {
    static func encrypt(domain: String, with key: SymmetricKey) throws -> String {
        let host = URL(string: domain)?.host ?? domain
        return try key.encrypt(host)
    }

    static func positiveFileName(for domain: String, with key: SymmetricKey) throws -> String {
        let encryptedFileName = try encrypt(domain: domain, with: key)
        return "\(encryptedFileName).positive"
    }

    static func negativeFileName(for domain: String, with key: SymmetricKey) throws -> String {
        let encryptedFileName = try encrypt(domain: domain, with: key)
        return "\(encryptedFileName).negative"
    }

    static func cache(data: Data?, fileName: String, containerUrl: URL) throws {
        // Create the containing folder if not exist first
        if !FileManager.default.fileExists(atPath: containerUrl.path) {
            try FileManager.default.createDirectory(at: containerUrl,
                                                    withIntermediateDirectories: true)
        }

        let fileUrl = containerUrl.appendingPathComponent(fileName, conformingTo: .data)
        FileManager.default.createFile(atPath: fileUrl.path, contents: data)
    }

    static func getDataRemovingIfObsolete(fileName: String,
                                          containerUrl: URL,
                                          isObsolete: Bool) throws -> Data? {
        let fileUrl = containerUrl.appendingPathComponent(fileName, conformingTo: .data)

        guard FileManager.default.fileExists(atPath: fileUrl.path) else { return nil }

        if isObsolete {
            // Removal might fail, we don't care
            // so we ignore the error by doing `try?` instead of `try`
            try? FileManager.default.removeItem(at: fileUrl)
            return nil
        }
        return try Data(contentsOf: fileUrl)
    }

    /// Do not care if the file exist or not.
    /// Consider obsolete by default if the file does not exist or fail to get file's attributes
    static func isObsolete(fileName: String,
                           containerUrl: URL,
                           currentDate: Date,
                           thresholdInDays: Int) -> Bool {
        let fileUrl = containerUrl.appendingPathComponent(fileName, conformingTo: .data)
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileUrl.path) else {
            return true
        }

        if let creationDate = attributes[.creationDate] as? Date {
            let numberOfDays = Calendar.current.numberOfDaysBetween(creationDate,
                                                                    and: currentDate)
            return abs(numberOfDays) >= thresholdInDays
        }

        return true
    }
}
