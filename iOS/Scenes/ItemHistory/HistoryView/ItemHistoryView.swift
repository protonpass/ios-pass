//
//
// ItemHistoryView.swift
// Proton Pass - Created on 09/01/2024.
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
//

import SwiftUI

struct ItemHistoryView: View {
    @StateObject var viewModel: ItemHistoryViewModel

    var body: some View {
        mainContainer
            .task {
                await viewModel.loadItemHistory()
            }
    }
}

private extension ItemHistoryView {
    var mainContainer: some View {
        ForEach(viewModel.itemStates, id: \.itemUuid) { item in
            VStack {
                Text("Item revision \(item.item.revision)")
            }
        }
    }
}

//
// struct ItemHistoryView_Previews: PreviewProvider {
//    static var previews: some View {
//        ItemHistoryView()
//    }
// }
