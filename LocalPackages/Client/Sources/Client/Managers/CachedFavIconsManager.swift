//
// CachedFavIconsManager.swift
// Proton Pass - Created on 31/10/2024.
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

import Foundation
import UIKit

public protocol CachedFavIconsManagerProtocol {
    func cache(url: String, image: UIImage)
    func get(for url: String) -> UIImage?
}

public final class CachedFavIconsManager: CachedFavIconsManagerProtocol {
    private let cachedData = NSCache<NSString, UIImage>()

    public init(countLimit: Int = 20) {
        cachedData.countLimit = countLimit
    }

    public func cache(url: String, image: UIImage) {
        cachedData.setObject(image, forKey: NSString(string: url))
    }

    public func get(for url: String) -> UIImage? {
        cachedData.object(forKey: NSString(string: url))
    }
}
