//
// ItemsTabOptionsButton.swift
// Proton Pass - Created on 30/11/2023.
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
import ProtonCoreUIFoundations
import SwiftUI

struct ItemsTabOptionsButton: View {
    @StateObject private var viewModel = ItemsTabOptionsButtonViewModel()
    var onSelectItems: () -> Void

    var body: some View {
        Menu(content: {
            if viewModel.selectable {
                Button(action: onSelectItems) {
                    Label(title: {
                        Text("Select items")
                    }, icon: {
                        IconProvider.checkmarkCircle
                    })
                }
            }

            // Filter options
            let selectedFilterOption = viewModel.selectedFilterOption
            let itemCount = viewModel.itemCount
            Menu(content: {
                ForEach(ItemTypeFilterOption.allCases, id: \.self) { option in
                    let uiModel = option.uiModel(from: itemCount)
                    Button(action: {
                        viewModel.updateFilterOption(option)
                    }, label: {
                        Label(title: {
                            text(for: uiModel)
                        }, icon: {
                            if option == selectedFilterOption {
                                Image(systemName: "checkmark")
                            }
                        })
                    })
                    // swiftformat:disable:next isEmpty
                    .disabled(uiModel.count == 0) // swiftlint:disable:this empty_count
                }
            }, label: {
                Label(title: {
                    // Use Button to trick SwiftUI into rendering option with title and subtitle
                    Button(action: {}, label: {
                        Text("Show")
                        text(for: selectedFilterOption.uiModel(from: itemCount))
                    })
                }, icon: {
                    Image(uiImage: IconProvider.filter)
                })
            })

            // Sort options
            let selectedSortType = viewModel.selectedSortType
            Menu(content: {
                ForEach(SortType.allCases, id: \.self) { type in
                    Button(action: {
                        viewModel.selectedSortType = type
                    }, label: {
                        HStack {
                            Text(type.title)
                            Spacer()
                            if type == selectedSortType {
                                Image(systemName: "checkmark")
                            }
                        }
                    })
                }
            }, label: {
                Label(title: {
                    Button(action: {}, label: {
                        Text("Sort By")
                        Text(verbatim: selectedSortType.title)
                    })
                }, icon: {
                    Image(uiImage: IconProvider.arrowDownArrowUp)
                })
            })
        }, label: {
            CircleButton(icon: IconProvider.threeDotsVertical,
                         iconColor: viewModel.highlighted ? PassColor.textInvert : PassColor.interactionNormMajor2,
                         backgroundColor: viewModel.highlighted ? PassColor.interactionNormMajor2 : .clear)
        })
    }
}

private extension ItemsTabOptionsButton {
    func text(for uiModel: ItemTypeFilterOptionUiModel) -> some View {
        Text(verbatim: "\(uiModel.title) (\(uiModel.count))")
    }
}
