//
// ItemCountView.swift
// Proton Pass - Created on 30/03/2023.
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
import DesignSystem
import Entities
import Factory
import SwiftUI

private let kChipHeight: CGFloat = 56

struct ItemCountView: View {
    @StateObject private var vaultsManager = resolve(\SharedServiceContainer.vaultsManager)
    let onSelect: (ItemContentType) -> Void

    var body: some View {
        switch vaultsManager.state {
        case .loading:
            skeleton
        case let .loaded(vaults, trashedItems):
            let activeItems = vaults.map(\.items).reduce(into: []) { $0 += $1 }
            let allItems = activeItems + trashedItems
            let itemCount = ItemCount(items: allItems)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ItemContentTypeCountView(type: .login,
                                             count: itemCount.login,
                                             onSelect: onSelect)
                    ItemContentTypeCountView(type: .alias,
                                             count: itemCount.alias,
                                             onSelect: onSelect)
                    ItemContentTypeCountView(type: .creditCard,
                                             count: itemCount.creditCard,
                                             onSelect: onSelect)
                    ItemContentTypeCountView(type: .note,
                                             count: itemCount.note,
                                             onSelect: onSelect)
                    ItemContentTypeCountView(type: .identity,
                                             count: itemCount.identity,
                                             onSelect: onSelect)
                }
                .padding(.horizontal)
            }
        case let .error(error):
            Text(error.localizedDescription)
                .foregroundStyle(PassColor.signalDanger.toColor)
        }
    }

    private var skeleton: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(0...5, id: \.self) { _ in
                    SkeletonBlock()
                        .frame(width: 100, height: kChipHeight)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
            .shimmering()
        }
        .scrollDisabled(true)
    }
}

private struct ItemContentTypeCountView: View {
    let type: ItemContentType
    let count: Int
    let onSelect: (ItemContentType) -> Void

    var body: some View {
        HStack {
            CircleButton(icon: type.regularIcon,
                         iconColor: type.normColor,
                         backgroundColor: type.normMinor1Color,
                         type: .small)

            Spacer()

            Text(verbatim: "\(count)")
                .fontWeight(.bold)
                .foregroundStyle(PassColor.textNorm.toColor)

            Spacer()
        }
        .padding(10)
        .frame(height: kChipHeight)
        .frame(minWidth: 103)
        .overlay(Capsule().strokeBorder(PassColor.inputBorderNorm.toColor, lineWidth: 1))
        .contentShape(.rect)
        .onTapGesture {
            if count > 0 { // swiftlint:disable:this empty_count
                onSelect(type)
            }
        }
    }
}
