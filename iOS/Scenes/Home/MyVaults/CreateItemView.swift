//
// CreateItemView.swift
// Proton Pass - Created on 07/07/2022.
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

import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct CreateItemView: View {
    @Environment(\.presentationMode) private var presentationMode
    let coordinator: MyVaultsCoordinator

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                GenericItemView(item: CreateNewItemOption.login) {
                    coordinator.handleCreateNewItemOption(.login)
                }

                GenericItemView(item: CreateNewItemOption.alias) {
                    coordinator.handleCreateNewItemOption(.alias)
                }

                GenericItemView(item: CreateNewItemOption.note) {
                    coordinator.handleCreateNewItemOption(.note)
                }

                GenericItemView(item: CreateNewItemOption.password,
                                showDivider: false) {
                    coordinator.handleCreateNewItemOption(.password)
                }

                Spacer()
            }
            .navigationTitle("Create new...")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Image(uiImage: IconProvider.cross)
                    })
                    .foregroundColor(Color(.label))
                }
            }
        }
    }
}

struct CreateItemView_Previews: PreviewProvider {
    static var previews: some View {
        CreateItemView(coordinator: .preview)
    }
}

enum CreateNewItemOption: GenericItemProvider {
    case login, alias, note, password

    var icon: UIImage {
        switch self {
        case .login:
            return IconProvider.keySkeleton
        case .alias:
            return IconProvider.alias
        case .note:
            return IconProvider.note
        case .password:
            return IconProvider.arrowsRotate
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
            return "Generate password"
        }
    }

    var detail: String {
        switch self {
        case .login:
            return "Keep your username and password secure"
        case .alias:
            return "Hide your identity with a separate email address"
        case .note:
            return "Keep important information secure"
        case .password:
            return "Generate a secure password"
        }
    }
}
