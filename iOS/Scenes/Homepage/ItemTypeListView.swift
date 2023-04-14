//
// ItemTypeListView.swift
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

import Client
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

enum ItemType: CaseIterable {
    case login, alias, note, password

    var icon: UIImage {
        switch self {
        case .login:
            return IconProvider.user
        case .alias:
            return IconProvider.alias
        case .note:
            return IconProvider.fileLines
        case .password:
            return IconProvider.key
        }
    }

    var tintColor: UIColor {
        switch self {
        case .login:
            return ItemContentType.login.normMajor1Color
        case .alias:
            return ItemContentType.alias.normMajor1Color
        case .note:
            return ItemContentType.note.normMajor1Color
        case .password:
            return PassColor.passwordInteractionNormMajor1
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .login:
            return ItemContentType.login.normMinor1Color
        case .alias:
            return ItemContentType.alias.normMinor1Color
        case .note:
            return ItemContentType.note.normMinor1Color
        case .password:
            return PassColor.passwordInteractionNormMinor1
        }
    }

    var title: String {
        switch self {
        case .login:
            return "Login"
        case .alias:
            return "Alias"
        case .note:
            return "Note"
        case .password:
            return "Password"
        }
    }

    var description: String {
        switch self {
        case .login:
            return "Add login details for an app or site"
        case .alias:
            return "Get an email alias to use on new apps"
        case .note:
            return "Jot down a PIN, code, or note to self"
        case .password:
            return "Generate a secure password"
        }
    }
}

struct ItemTypeListView: View {
    let onSelectItemType: (ItemType) -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(ItemType.allCases, id: \.self) { type in
                        itemRow(for: type)
                            .padding(.horizontal)
                        if type != ItemType.allCases.last {
                            PassDivider()
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .background(Color(uiColor: PassColor.backgroundWeak))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    NavigationTitleWithHandle(title: "Create")
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private func itemRow(for type: ItemType) -> some View {
        Button(action: {
            onSelectItemType(type)
        }, label: {
            GeneralItemRow(
                thumbnailView: {
                    SquircleThumbnail(data: .icon(type.icon),
                                      tintColor: type.tintColor,
                                      backgroundColor: type.backgroundColor)
                },
                title: type.title,
                description: type.description)
            .frame(height: 66)
        })
        .buttonStyle(.plain)
    }
}
