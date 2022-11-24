//
// GeneratePasswordView.swift
// Proton Pass - Created on 24/07/2022.
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

struct GeneratePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: GeneratePasswordViewModel

    init(viewModel: GeneratePasswordViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            NotchView()
                .padding(.top, 5)
                .padding(.bottom, 7)

            titleView

            Text(viewModel.texts)
                .font(.title3)
                .fontWeight(.bold)
                .minimumScaleFactor(0.5)
                .frame(maxHeight: .infinity, alignment: .center)
                .padding(.horizontal)
                .transaction { transaction in
                    transaction.animation = nil
                }

            Divider()
                .padding(.vertical, 24)

            HStack {
                Text("\(Int(viewModel.length)) characters")
                    .frame(minWidth: 120, alignment: .leading)
                    .transaction { transaction in
                        transaction.animation = nil
                    }
                Slider(value: $viewModel.length,
                       in: 4...64,
                       step: 1)
                .accentColor(.interactionNorm)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            Toggle(isOn: $viewModel.hasSpecialCharacters) {
                Text("Special characters")
            }
            .toggleStyle(SwitchToggleStyle.proton)
            .padding(.horizontal, 16)

            Spacer()

            Button(action: {
                viewModel.confirm()
                if case .createLogin = viewModel.mode {
                    dismiss()
                }
            }, label: {
                Text(viewModel.mode.confirmTitle)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            })
            .padding()
            .background(Color.interactionNorm)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding()
        }
        .animation(.default, value: viewModel.password)
    }

    private var titleView: some View {
        ZStack {
            Text("Generate password")
                .fontWeight(.bold)
            HStack {
                Spacer()
                Button(action: dismiss.callAsFunction) {
                    ZStack {
                        Color.secondary.opacity(0.5)
                        Image(uiImage: IconProvider.cross)
                            .foregroundColor(.secondary)
                            .frame(width: 12, height: 12)
                    }
                    .clipShape(Circle())
                    .frame(width: 30, height: 30)
                }
                .padding(.trailing)
            }
        }
    }
}

/*
struct GeneratePasswordView_Previews: PreviewProvider {
    static var previews: some View {
        GeneratePasswordView(viewModel: .init(mode: .random))
    }
}
*/
