//
// TrashView.swift
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

struct TrashView: View {
    let coordinator: TrashCoordinator

    var body: some View {
        List {
            ForEach(0..<30, id: \.self) { index in
                Text("Item #\(index)")
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                ToggleSidebarButton(action: coordinator.showSidebar)
            }

            ToolbarItem(placement: .principal) {
                Text("Trash")
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Menu(content: {
                    Button(action: {
                        print("Empty trash")
                    }, label: {
                        Label(title: {
                            Text("Empty trash")
                        }, icon: {
                            Image(uiImage: IconProvider.trash)
                        })
                    })
                }, label: {
                    Image(uiImage: IconProvider.threeDotsHorizontal)
                        .foregroundColor(Color(.label))
                })
            }
        }
    }
}

struct TrashView_Previews: PreviewProvider {
    static var previews: some View {
        TrashView(coordinator: .preview)
    }
}
