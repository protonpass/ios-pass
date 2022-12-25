//
// ItemCountView.swift
// Proton Pass - Created on 14/11/2022.
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
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct ItemCountView: View {
    let itemCount: ItemCount?
    let onSelectAll: () -> Void
    let onSelectType: (ItemContentType) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onSelectAll) {
                HStack {
                    Label(title: {
                        Text("All items")
                            .foregroundColor(.sidebarTextNorm)
                    }, icon: {
                        Image(uiImage: IconProvider.vault)
                            .foregroundColor(.sidebarIconWeak)
                    })

                    Spacer()

                    if let itemCount {
                        Text("\(itemCount.total)")
                            .foregroundColor(.white)
                            .font(.callout)
                    } else {
                        ProgressView()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.sidebarItem)

            ForEach(ItemContentType.allCases, id: \.self) { type in
                ItemContentTypeCountView(type: type,
                                         count: itemCount?.typeCountDictionary[type],
                                         onSelect: { onSelectType(type) })
            }
        }
    }
}

private struct ItemContentTypeCountView: View {
    let type: ItemContentType
    let count: Int?
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Label(title: {
                    Text(type.countTitle)
                        .foregroundColor(.sidebarTextNorm)
                }, icon: {
                    Image(uiImage: type.icon)
                        .foregroundColor(.sidebarIconWeak)
                })

                Spacer()

                if let count {
                    Text("\(count)")
                        .foregroundColor(.sidebarTextNorm)
                        .font(.callout)
                } else {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .padding(.leading, 27)
            .contentShape(Rectangle())
        }
        .buttonStyle(.sidebarItem)
        .disabled(count == nil)
    }
}
