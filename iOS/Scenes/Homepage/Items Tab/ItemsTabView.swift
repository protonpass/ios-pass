//
// ItemsTabView.swift
// Proton Pass - Created on 07/03/2023.
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

import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

private let kTopBarHeight: CGFloat = 48

struct ItemsTabView: View {
    @StateObject var viewModel: ItemsTabViewModel

    var body: some View {
        VStack {
            topBar
            if let selectedVault = viewModel.vaultsManager.selectedVault {
                Text(selectedVault.name)
            }
            Spacer()
        }
        .background(Color.passBackground)
    }

    private var topBar: some View {
        HStack {
            Button(action: viewModel.presentVaultList) {
                ZStack {
                    Color.passBrand
                        .opacity(0.16)
                    Image(uiImage: IconProvider.vault)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color.passBrand)
                        .padding(kTopBarHeight / 4)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .frame(width: kTopBarHeight)

            ZStack {
                Color.black
                HStack {
                    Image(uiImage: IconProvider.magnifier)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16)
                    Text("Search in all vaults...")
                }
                .foregroundColor(.textWeak)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .containerShape(Rectangle())
            .onTapGesture(perform: viewModel.search)
        }
        .padding(.horizontal)
        .frame(height: kTopBarHeight)
    }
}
