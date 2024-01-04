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
    @Binding var isEditMode: Bool
    @StateObject private var viewModel = ItemsTabOptionsButtonViewModel()

    var body: some View {
        Menu(content: {
            selectItemsButton
            filterOptions
            sortOptions
            resetFiltersButton
        }, label: {
            CircleButton(icon: IconProvider.threeDotsVertical,
                         iconColor: viewModel.highlighted ? PassColor.textInvert : PassColor.interactionNormMajor2,
                         backgroundColor: viewModel.highlighted ? PassColor.interactionNormMajor2 : .clear)
        })
    }
}

private extension ItemsTabOptionsButton {
    @ViewBuilder
    var selectItemsButton: some View {
        if viewModel.selectable {
            Button(action: {
                isEditMode = true
            }, label: {
                Label(title: {
                    Text("Select items")
                }, icon: {
                    IconProvider.checkmarkCircle
                })
            })
        }
    }
}

private extension ItemsTabOptionsButton {
    @ViewBuilder
    var filterOptions: some View {
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
                if #available(iOS 17, *) {
                    // Use Button to trick SwiftUI into rendering option with title and subtitle
                    Button(action: {}, label: {
                        Text("Show")
                        text(for: selectedFilterOption.uiModel(from: itemCount))
                    })
                } else {
                    text(for: selectedFilterOption.uiModel(from: itemCount))
                }
            }, icon: {
                Image(uiImage: viewModel.highlighted ? PassIcon.filterFilled : IconProvider.filter)
            })
        })
    }
}

private extension ItemsTabOptionsButton {
    @ViewBuilder
    var sortOptions: some View {
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
                if #available(iOS 17, *) {
                    Button(action: {}, label: {
                        Text("Sort By")
                        Text(verbatim: selectedSortType.title)
                    })
                } else {
                    Text(verbatim: selectedSortType.title)
                }
            }, icon: {
                Image(uiImage: IconProvider.arrowDownArrowUp)
            })
        })
    }
}

private extension ItemsTabOptionsButton {
    func text(for uiModel: ItemTypeFilterOptionUiModel) -> some View {
        Text(verbatim: "\(uiModel.title) (\(uiModel.count))")
    }
}

private extension ItemsTabOptionsButton {
    @ViewBuilder
    var resetFiltersButton: some View {
        if viewModel.resettable {
            Button(action: viewModel.resetFilters) {
                Label(title: {
                    Text("Reset filters")
                }, icon: {
                    IconProvider.crossCircle
                })
            }
        }
    }
}
