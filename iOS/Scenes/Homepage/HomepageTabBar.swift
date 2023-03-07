//
// HomepageTabBar.swift
// Proton Pass - Created on 06/03/2023.
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

import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

// swiftlint:disable:next type_name
enum Tab {
    case items, profile

    var icon: UIImage {
        switch self {
        case .items:
            return IconProvider.listBullets
        case .profile:
            return IconProvider.user
        }
    }
}

struct HomepageTabBar: View {
    @Binding var selectedTab: Tab
    let action: () -> Void

    var body: some View {
        HStack {
            Spacer()

            tab(for: .items)

            if !UIDevice.current.isIpad {
                Spacer()
                Spacer()
            }

            Button(action: action) {
                Image(uiImage: IconProvider.plus)
            }
            .buttonStyle(PlusButtonStyle(normalColor: .primary, pressedColor: .passBrand))
            .padding(.horizontal, UIDevice.current.isIpad ? 100 : 0)

            if !UIDevice.current.isIpad {
                Spacer()
                Spacer()
            }

            tab(for: .profile)

            Spacer()
        }
        .padding(.vertical, 16)
        .background(
            Color(uiColor: .init(red: 18, green: 18, blue: 27))
                .opacity(0.8)
        )
        .background(.ultraThinMaterial)
    }

    private func tab(for tab: Tab) -> some View {
        Button(action: {
            selectedTab = tab
        }, label: {
            Image(uiImage: tab.icon)
                .foregroundColor(selectedTab == tab ? .passBrand : .primary)
        })
    }
}

private struct PlusButtonStyle: ButtonStyle {
    let normalColor: Color
    let pressedColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundColor(configuration.isPressed ? pressedColor : normalColor)
    }
}
