//
// FavIconProvider.swift
// Proton Pass - Created on 13/04/2023.
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
import ProtonCore_Networking
import ProtonCore_Services

private let kCacheExpirationDays = 14
private let kContainerUrl = URL.favIconContainerURL()

protocol FavIconProviderProtocol {
    var apiService: APIService { get }

    func getFavIconData(for domain: String) async throws -> Data?
}

extension FavIconProviderProtocol {
    func getFavIconData(for domain: String) async throws -> Data? {
        let cacheResult = try getResultFromCache(for: domain)

        switch cacheResult {
        case .exist(let data):
            return data

        case .notExist:
            return nil

        case .miss:
            let fetchResult = try await fetchData(for: domain)

            switch fetchResult {
            case .positive(let data):
                try cache(data: data, domain: domain)
                return data

            case .negative:
                try cache(data: nil, domain: domain)
                return nil
            }
        }
    }
}

private extension FavIconProviderProtocol {
    func getResultFromCache(for domain: String) throws -> CacheResult {
        // Check if already downloaded
        let existFileUrl = kContainerUrl.appendingPathComponent(domain.existFileName)
        if FileManager.default.fileExists(atPath: existFileUrl.path) {
            if let existData = try getDataOrDelete(at: existFileUrl) {
                return .exist(existData)
            }
        }

        // Check if already downloaded but no result
        let notExistFileUrl = kContainerUrl.appendingPathComponent(domain.notExistFileName)
        if FileManager.default.fileExists(atPath: notExistFileUrl.path) {
            _ = try getDataOrDelete(at: notExistFileUrl)
            return .notExist
        }

        return .miss
    }

    func getDataOrDelete(at url: URL) throws -> Data? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)

        // Remove the file if obsolete
        if let creationDate = attributes[.creationDate] as? Date {
            let numberOfDays = Calendar.current.numberOfDaysBetween(creationDate, and: .now)
            if abs(numberOfDays) >= kCacheExpirationDays {
                try FileManager.default.removeItem(at: url)
                return nil
            }
        }

        return try Data(contentsOf: url)
    }

    func fetchData(for domain: String) async throws -> FetchResult {
        let endpoint = GetLogoEndpoint(domain: domain)
        let response = try await apiService.execExpectingData(endpoint: endpoint)

        switch response.httpResponse.statusCode {
        case 200, 204:
            if let data = response.data {
                return .positive(data)
            } else {
                return .negative(.notExist)
            }

        default:
            if let protonCode = response.protonCode,
               let businessError = BusinessError(rawValue: protonCode) {
                return .negative(.businessError(businessError))
            }
            throw PPError.unexpectedHttpStatusCode(response.httpResponse.statusCode)
        }
    }

    func cache(data: Data?, domain: String) throws {
        // Create the containing folder if not exist first
        if !FileManager.default.fileExists(atPath: kContainerUrl.pathExtension) {
            try FileManager.default.createDirectory(at: kContainerUrl,
                                                    withIntermediateDirectories: false)
        }

        // Then create the file
        let fileUrl: URL
        if data != nil {
            fileUrl = kContainerUrl.appendingPathComponent(domain.existFileName)
        } else {
            fileUrl = kContainerUrl.appendingPathComponent(domain.notExistFileName)
        }
        FileManager.default.createFile(atPath: fileUrl.path, contents: data)
    }
}

final class FavIconProvider: FavIconProviderProtocol {
    let apiService: APIService

    init(apiService: APIService) {
        self.apiService = apiService
    }
}

private enum CacheResult {
    /// The image is downloaded before and still valid
    case exist(Data)

    /// The image does not exist and no need to try to download
    /// because we already tried to download before and encounter`NegativityReason`
    case notExist

    /// Can't tell if the image is downloaded but flushed or never downloaded
    /// simply try to download in this case
    case miss
}

private enum FetchResult {
    case positive(Data)
    case negative(NegativityReason)
}

/// Reason why a fav icon is null
private enum NegativityReason {
    /// Everything is ok, the image simply does not exist
    case notExist

    /// Domain error
    case businessError(BusinessError)
}

/// Known domain errors
private enum BusinessError: Int {
    case notTrusted = 2_011
    case invalidAddress = -1
    case failedToFindForAppropriateSize = 2_511
    case failedToFind = 2_902
}

private extension URL {
    static func favIconContainerURL() -> URL {
        guard let fileContainer = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Constants.appGroup) else {
            fatalError("Can not create folder for fav icons")
        }
        return fileContainer.appendingPathComponent("FavIcons", isDirectory: true)
    }
}

private extension String {
    var existFileName: String { "\(sha256).exist" }
    var notExistFileName: String { "\(sha256).notexist" }
}
