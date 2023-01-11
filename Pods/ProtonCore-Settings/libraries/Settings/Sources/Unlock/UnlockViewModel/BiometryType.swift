//
//  BiometryType.swift
//  ProtonCore-Settings - Created on 30.10.2020.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCore_UIFoundations

public enum BiometryType {
    case face
    case touch
    case none
}

extension BiometryType {
    var technologyName: String {
        switch self {
        case .face: return "FaceID"
        case .touch: return "TouchID"
        case .none: return ""
        }
    }

    var image: UIImage {
        switch self {
        case .face: return IconProvider.faceId
        case .touch: return IconProvider.touchId
        case .none: return IconProvider.touchId
        }
    }

    var buttonText: String? {
        switch self {
        case .face: return "Open with FaceID"
        case .touch: return "Open with TouchID"
        case .none: return nil
        }
    }
}
