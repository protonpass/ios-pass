//
//  PasswordConfigurationViewModel.swift
//  ProtonCore-Settings - Created on 02.10.2020.
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

typealias Observer<T> = (T) -> Void

protocol PasswordConfigurationViewModel {
    var title: String { get }
    var textFieldTitle: String { get }
    var buttonText: String { get }
    var rightBarButtonImage: UIImage { get }
    var caption: String { get }

    func advance()
    func withdrawFromScreen()
    func userInputDidChange(to text: String)
    func viewWillDissapear()
}
