//
// PassColor.swift
// Proton Pass - Created on 05/04/2023.
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

// swiftlint:disable force_unwrapping
import UIKit

public enum PassColor {}

public extension PassColor {
    static var interactionNorm = UIColor(named: "InteractionNorm")!
    static var interactionNormMajor1 = UIColor(named: "InteractionNormMajor1")!
    static var interactionNormMajor2 = UIColor(named: "InteractionNormMajor2")!
    static var interactionNormMinor1 = UIColor(named: "InteractionNormMinor1")!
    static var interactionNormMinor2 = UIColor(named: "InteractionNormMinor2")!

    static var loginInteractionNorm = UIColor(named: "LoginInteractionNorm")!
    static var loginInteractionNormMajor1 = UIColor(named: "LoginInteractionNormMajor1")!
    static var loginInteractionNormMajor2 = UIColor(named: "LoginInteractionNormMajor2")!
    static var loginInteractionNormMinor1 = UIColor(named: "LoginInteractionNormMinor1")!
    static var loginInteractionNormMinor2 = UIColor(named: "LoginInteractionNormMinor2")!
}
