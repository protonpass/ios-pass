//
// SortFilterItemsMenu.swift
// Proton Pass - Created on 15/10/2024.
// Copyright (c) 2024 Proton Technologies AG
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
import ProtonCoreUIFoundations
import SwiftUI

enum SortFilterItemsMenuOption: Identifiable {
    // Enter bulk action mode (select multi items)
    case selectItems(() -> Void)
    case filter(ItemTypeFilterOption, ItemCount, (ItemTypeFilterOption) -> Void)
    case sort(SortType, (SortType) -> Void)
    case resetFilters(() -> Void)

    var id: String {
        UUID().uuidString
    }
}

struct SortFilterItemsMenu: View {
    let options: [SortFilterItemsMenuOption]
    let highlighted: Bool
    let selectable: Bool

    var body: some View {
        Menu(content: {
            ForEach(options) { option in
                switch option {
                case let .selectItems(onSelect):
                    if selectable {
                        Button(action: onSelect) {
                            Label(title: {
                                Text("Select items")
                            }, icon: {
                                IconProvider.checkmarkCircle
                            })
                        }
                    }

                case let .filter(selectedOption, itemCount, onSelect):
                    filterOptions(selectedOption: selectedOption,
                                  itemCount: itemCount,
                                  onSelect: onSelect)

                case let .sort(selectedType, onSelect):
                    sortOptions(selectedType: selectedType, onSelect: onSelect)

                case let .resetFilters(onReset):
                    if highlighted {
                        Button(action: onReset) {
                            Label(title: {
                                Text("Reset filters")
                            }, icon: {
                                IconProvider.arrowUpAndLeft
                            })
                        }
                    }
                }
            }
        }, label: {
            CircleButton(icon: IconProvider.threeDotsVertical,
                         iconColor: highlighted ? PassColor.textInvert : PassColor.interactionNormMajor2,
                         backgroundColor: highlighted ? PassColor.interactionNormMajor1 : .clear)
        })
        .accessibilityLabel(Text("Items filtering and sort menu"))
    }
}

private extension SortFilterItemsMenu {
    func filterOptions(selectedOption: ItemTypeFilterOption,
                       itemCount: ItemCount,
                       onSelect: @escaping (ItemTypeFilterOption) -> Void) -> some View {
        Menu(content: {
            ForEach(filterOptions, id: \.self) { option in
                let uiModel = option.uiModel(from: itemCount)
                Button(action: {
                    onSelect(option)
                }, label: {
                    Label(title: {
                        text(for: uiModel)
                    }, icon: {
                        if option == selectedOption {
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
                        text(for: selectedOption.uiModel(from: itemCount))
                    })
                } else {
                    text(for: selectedOption.uiModel(from: itemCount))
                }
            }, icon: {
                !selectedOption.isDefault ? PassIcon.filterFilled : IconProvider.filter
            })
        })
    }

    var filterOptions: [ItemTypeFilterOption] {
        [
            .all,
            .precise(.login),
            .precise(.alias),
            .precise(.creditCard),
            .precise(.note),
            .precise(.identity),
            .precise(.custom),
            .itemSharedWithMe,
            .itemSharedByMe
        ]
    }

    func text(for uiModel: ItemTypeFilterOptionUiModel) -> some View {
        Text(verbatim: "\(uiModel.title) (\(uiModel.count))")
    }
}

private extension SortFilterItemsMenu {
    func sortOptions(selectedType: SortType,
                     onSelect: @escaping (SortType) -> Void) -> some View {
        Menu(content: {
            ForEach(SortType.allCases, id: \.self) { type in
                Button(action: {
                    onSelect(type)
                }, label: {
                    HStack {
                        Text(type.title)
                        Spacer()
                        if type == selectedType {
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
                        Text(verbatim: selectedType.title)
                    })
                } else {
                    Text(verbatim: selectedType.title)
                }
            }, icon: {
                IconProvider.arrowDownArrowUp
            })
        })
    }
}
