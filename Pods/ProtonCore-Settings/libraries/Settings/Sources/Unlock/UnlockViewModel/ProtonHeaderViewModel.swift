//
//  ProtonHeaderViewModel.swift
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

public enum ProtonHeaderViewModel {
    case vpn(subtitle: String?)
    case mail(subtitle: String?)
    case drive(subtitle: String?)
    case calendar(subtitle: String?)

    var image: UIImage {
        switch self {
        case .vpn: return IconProvider.vpnWordmarkNoBackground
        case .mail: return IconProvider.mailWordmarkNoBackground
        case .drive: return IconProvider.driveWordmarkNoBackground
        case .calendar: return IconProvider.calendarWordmarkNoBackground
        }
    }

    var subtitle: String? {
        switch self {
        case let .vpn(subtitle): return subtitle
        case let .mail(subtitle): return subtitle
        case let .drive(subtitle): return subtitle
        case let .calendar(subtitle): return subtitle
        }
    }
}
