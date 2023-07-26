//
// SyncLayoutOnDisappear.swift
// Proton Pass - Created on 26/07/2023.
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

import SwiftUI

/// https://developer.apple.com/forums/thread/718495
/// https://developer.apple.com/forums/thread/724598?answerId=746253022#746253022
/// This modifier is used to fix an issue of offset appearing on Home page screen after the dismiss of a sheet content
/// This modifier should be applied to the content of the sheet being presented to force a recalculation of the view frame
public struct SyncLayoutOnDisappear: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            .onDisappear {
                let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                if let viewFrame = scene?.windows.first?.rootViewController?.view.frame {
                    scene?.windows.first?.rootViewController?.view.frame = .zero
                    scene?.windows.first?.rootViewController?.view.frame = viewFrame
                }
            }
    }
}
