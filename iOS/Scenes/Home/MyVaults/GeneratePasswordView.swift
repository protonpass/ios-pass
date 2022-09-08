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
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: GeneratePasswordViewModel

    init(viewModel: GeneratePasswordViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    VStack {
                        Text(viewModel.texts)
                            .font(.title3)
                            .fontWeight(.bold)
                            .transaction { transaction in
                                transaction.animation = nil
                            }
                        Spacer()
                    }
                    Spacer()
                    VStack {
                        Button(action: viewModel.regenerate) {
                            Image(uiImage: IconProvider.arrowsRotate)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
                .frame(height: 120)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding()

                Divider()

                HStack {
                    Text("\(Int(viewModel.length)) characters")
                        .frame(minWidth: 120, alignment: .leading)
                    Slider(value: $viewModel.length,
                           in: 4...64,
                           step: 1)
                    .accentColor(Color(ColorProvider.BrandNorm))
                }
                .padding([.horizontal, .top])

                Toggle(isOn: $viewModel.hasSpecialCharacters) {
                    Text("Special characters")
                }
                .toggleStyle(SwitchToggleStyle.proton)
                .padding(.horizontal)

                Spacer()

                Button(action: {
                    viewModel.confirm()
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("Confirm")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                })
                .padding()
                .background(Color(ColorProvider.BrandNorm))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding()
            }
            .animation(.default, value: viewModel.password)
            .navigationBarTitle("Generate password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Image(uiImage: IconProvider.cross)
                    .foregroundColor(.primary)
            })
        }
    }
}

struct GeneratePasswordView_Previews: PreviewProvider {
    static var previews: some View {
        GeneratePasswordView(viewModel: .init())
    }
}
