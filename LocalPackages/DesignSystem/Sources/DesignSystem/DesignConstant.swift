//
// DesignConstant.swift
// Proton Pass - Created on 09/10/2023.
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

import Foundation

public enum DesignConstant {
    public static let sectionPadding: CGFloat = 16
    public static let defaultPickerHeight: CGFloat = 50
    public static let searchBarHeight: CGFloat = 48
    public static let previewBreachItemCount = 5
    public static let onboardingPadding: CGFloat = 24

    // SwiftUI's default animation duration is 0.35
    // https://developer.apple.com/documentation/swiftui/animation/linear#
    public static let animationDuration: CGFloat = 0.35

    public enum Icons {
        public static let defaultIconSize: CGFloat = 20
    }
}
