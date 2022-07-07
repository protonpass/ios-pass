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
    let coordinator: MyVaultsCoordinator

    var body: some View {
        NavigationView {
            VStack {
                GenericItemView(item: CreateNewItemOption.newLogin) {
                    coordinator.handleCreateNewItemOption(.newLogin)
                }

                GenericItemView(item: CreateNewItemOption.newAlias) {
                    coordinator.handleCreateNewItemOption(.newAlias)
                }

                GenericItemView(item: CreateNewItemOption.newNote) {
                    coordinator.handleCreateNewItemOption(.newNote)
                }

                Text("Other")
                    .foregroundColor(Color(.secondaryLabel))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.vertical, .leading])

                GenericItemView(item: CreateNewItemOption.generatePassword) {
                    coordinator.handleCreateNewItemOption(.generatePassword)
                }

                Spacer()
            }
            .navigationTitle("Create new item")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: coordinator.dismissTopMostModal) {
                        Image(uiImage: IconProvider.cross)
                    }
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
    case newLogin, newAlias, newNote, generatePassword

    var icon: UIImage {
        switch self {
        case .newLogin:
            return IconProvider.keySkeleton
        case .newAlias:
            return IconProvider.alias
        case .newNote:
            return IconProvider.note
        case .generatePassword:
            return IconProvider.arrowsRotate
        }
    }

    var title: String {
        switch self {
        case .newLogin:
            return "New Login"
        case .newAlias:
            return "New Alias"
        case .newNote:
            return "New Note"
        case .generatePassword:
            return "Generate Password"
        }
    }

    var detail: String? {
        switch self {
        case .newLogin:
            return "username/password"
        case .newAlias:
            return "Hide your real email address"
        case .newNote:
            return "Jot down any thought"
        case .generatePassword:
            return nil
        }
    }
}
