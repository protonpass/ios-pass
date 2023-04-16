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

public extension FavIconData {
    enum `Type` {
        case positive, negative
    }
}

public struct FavIconData: Hashable {
    public let domain: String
    public let data: Data?
    public let type: `Type`
}

/// Take care of fetching and caching behind the scenes
public protocol FavIconRepositoryProtocol {
    var datasource: RemoteFavIconDatasourceProtocol { get }
    /// URL to the folder that contains cached fav icons
    var containerUrl: URL { get }
    var cacheExpirationDays: Int { get }
    var domainParser: DomainParser { get }
    var symmetricKey: SymmetricKey { get }

    /// Return `Data` if any (whether from cache or newly fetched we don't care)
    /// Return `nil` if the fav icon doesn't exist or fetched but encountered a known `FavIconError`
    /// We also don't care
    ///
    /// Throw an error when encounter networking errors or not known errors.
    /// Can not do anything in this case but log the error and silently fail.
    func getFavIconData(for domain: String) async throws -> Data?

    func getAllCachedIcons() throws -> [FavIconData]
}

public extension FavIconRepositoryProtocol {
    func getFavIconData(for domain: String) async throws -> Data? {
        // Try to see if we have a postive cache
        let rootDomain =
        URLUtils.Sanitizer.sanitizeAndGetRootDomain(domain,
                                                    domainParser: domainParser) ?? domain
        let positiveFileName = try FavIconCacheUtils.positiveFileName(for: rootDomain,
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
        let negativeFileName = try FavIconCacheUtils.negativeFileName(for: rootDomain,
                                                                      with: symmetricKey)
        let negativeFileData = try getDataOrRemoveIfObsolete(fileName: negativeFileName)
        if negativeFileData != nil {
            return nil
        }

        // Nothing is cached (or cache is obsolete and deleted), fetch from remote
        let result = try await datasource.fetchFavIcon(for: rootDomain)

        switch result {
        case .positive(let data):
            try FileUtils.createOrOverwrite(data: data,
                                            fileName: positiveFileName,
                                            containerUrl: containerUrl)
            return data
        case .negative:
            try FileUtils.createOrOverwrite(data: nil,
                                            fileName: negativeFileName,
                                            containerUrl: containerUrl)
            return nil
        }
    }

    func getAllCachedIcons() throws -> [FavIconData] {
        let urls = try FileManager.default.contentsOfDirectory(at: containerUrl,
                                                               includingPropertiesForKeys: nil)
        return try urls.map { url -> FavIconData? in
            var type: FavIconData.`Type`?
            let pathExtension = url.pathExtension
            switch pathExtension {
            case "positive":
                type = .positive
            case "negative":
                type = .negative
            default:
                return nil
            }

            let base64FileName = url.deletingPathExtension().lastPathComponent
            guard let fileNameData = try base64FileName.base64Decode(),
                  let encryptedFileName = String(data: fileNameData, encoding: .utf8) else {
                throw PPClientError.crypto(.failedToBase64Decode)
            }
            let decryptedFileName = try symmetricKey.decrypt(encryptedFileName)

            if let type {
                let data = try Data(contentsOf: url)
                return FavIconData(domain: decryptedFileName,
                                   data: data.isEmpty ? nil : data,
                                   type: type)
            }

            return nil
        }.compactMap { $0 }
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
    func getDataOrRemoveIfObsolete(fileName: String) throws -> Data? {
        let fileUrl = containerUrl.appendingPathComponent(fileName, conformingTo: .data)
        let isObsolete = FileUtils.isObsolete(url: fileUrl,
                                              currentDate: .now,
                                              thresholdInDays: cacheExpirationDays)

        let fileData = try FileUtils.getDataRemovingIfObsolete(url: fileUrl,
                                                               isObsolete: isObsolete)
        return fileData
    }
}

public final class FavIconRepository: FavIconRepositoryProtocol {
    public let datasource: RemoteFavIconDatasourceProtocol
    public let containerUrl: URL
    public let cacheExpirationDays: Int
    public let domainParser: DomainParser
    public let symmetricKey: SymmetricKey

    public init(apiService: APIService,
                containerUrl: URL,
                cacheExpirationDays: Int,
                domainParser: DomainParser,
                symmetricKey: SymmetricKey) {
        self.datasource = RemoteFavIconDatasource(apiService: apiService)
        self.containerUrl = containerUrl
        self.cacheExpirationDays = cacheExpirationDays
        self.domainParser = domainParser
        self.symmetricKey = symmetricKey
    }
}

enum FavIconCacheUtils {
    /// Symmetrically encrypt with a given key and then base 64 the cipher text
    /// Base 64 because symmetric encryption can produce slashes "/"
    /// Slashed are not allowed in file names hence confuses later file operations
    static func encryptAndBase64(text: String, with key: SymmetricKey) throws -> String {
        let cipherText = try key.encrypt(text)
        guard let base64 = cipherText.data(using: .utf8)?.base64EncodedString() else {
            throw PPClientError.crypto(.failedToBase64Encode)
        }
        return base64
    }

    /// Decrypt the encrypted &  base 64 cipher text produced by `encryptAndBase64(text:with:)`
    static func decrypt(base64: String, with key: SymmetricKey) throws -> String {
        guard let data = try base64.base64Decode(),
              let cipherText = String(data: data, encoding: .utf8) else {
            throw PPClientError.crypto(.failedToBase64Decode)
        }
        return try key.decrypt(cipherText)
    }

    /// Append "positive" as the extension of the file
    static func positiveFileName(for domain: String, with key: SymmetricKey) throws -> String {
        let encryptedFileName = try encryptAndBase64(text: domain, with: key)
        return "\(encryptedFileName).positive"
    }

    /// Append "negative" as the extension of the file
    static func negativeFileName(for domain: String, with key: SymmetricKey) throws -> String {
        let encryptedFileName = try encryptAndBase64(text: domain, with: key)
        return "\(encryptedFileName).negative"
    }
}
