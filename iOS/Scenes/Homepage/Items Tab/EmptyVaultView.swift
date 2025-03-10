//
// EmptyVaultView.swift
// Proton Pass - Created on 07/09/2022.
// Copyright (c) 2022 Proton Technologies AG
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
import DesignSystem
import Entities
import Factory
import ProtonCoreUIFoundations
import SwiftUI

struct EmptyVaultView: View {
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    private let canCreateItems: Bool
    private let customItemEnabled: Bool
    private let onCreate: (ItemContentType) -> Void

    @AppStorage(Constants.filterTypeKey, store: kSharedUserDefaults)
    private(set) var filterOption = ItemTypeFilterOption.all

    init(canCreateItems: Bool,
         customItemEnabled: Bool,
         onCreate: @escaping (ItemContentType) -> Void) {
        self.canCreateItems = canCreateItems
        self.customItemEnabled = customItemEnabled
        self.onCreate = onCreate
    }

    var body: some View {
        if filterOption.isDefault {
            createItemButtons
        } else {
            VStack {
                Spacer()
                Text("No items found")
                    .foregroundStyle(PassColor.textNorm.toColor)
                Spacer()
            }
        }
    }
}

private extension EmptyVaultView {
    var createItemButtons: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 0) {
                Text("Your vault is empty")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .padding(.bottom, 8)

                Text("Let's get started by creating your first item")
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 32)

                LazyVGrid(columns: columns) {
                    ForEach(ItemContentType.allCases, id: \.self) { type in
                        if isSupported(type) {
                            CreateItemButton(type: type) {
                                onCreate(type)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .opacityReduced(!canCreateItems)
    }
}

private extension EmptyVaultView {
    func isSupported(_ type: ItemContentType) -> Bool {
        switch type {
        case .alias, .creditCard, .identity, .login, .note:
            true

        case .sshKey, .wifi:
            false

        case .custom:
            customItemEnabled
        }
    }
}

private struct CreateItemButton: View {
    let type: ItemContentType
    let action: () -> Void

    var body: some View {
        let foregroundColor: UIColor = switch type {
        case .custom:
            PassColor.textNorm
        default:
            type.normColor
        }

        let backgroundColor: UIColor = switch type {
        case .custom:
            PassColor.customItemBackground
        default:
            type.normMinor1Color
        }

        Button(action: action) {
            VStack {
                Image(uiImage: type.regularIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 20, maxHeight: 20)
                    .padding(.top, 28)

                Text(type.createItemTitle)
                    .lineLimit(2)
                    .font(.callout)

                Spacer()
            }
            .frame(height: 122)
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.horizontal)
            .foregroundStyle(foregroundColor.toColor)
            .background(backgroundColor.toColor)
            .clipShape(RoundedRectangle(cornerRadius: 32))
        }
    }
}
