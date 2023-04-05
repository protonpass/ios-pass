//
// AccountView.swift
// Proton Pass - Created on 30/03/2023.
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

struct AccountView: View {
    @State private var isShowingSignOutConfirmation = false
    @StateObject var viewModel: AccountViewModel

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 0) {
                OptionRow(title: "Username",
                          height: .tall,
                          content: { Text(viewModel.username) })
                PassDivider()
                OptionRow(title: "Subscription Plan",
                          height: .tall,
                          content: { Text(viewModel.primaryPlan?.title ?? "Free") })
            }
            .roundedEditableSection()

            /*
            OptionRow(
                action: viewModel.manageSubscription,
                height: .tall,
                content: {
                    Text("Manage subscription")
                        .foregroundColor(.passBrand)
                },
                trailing: {
                    CircleButton(icon: IconProvider.arrowOutSquare,
                                 color: .passBrand,
                                 action: {})
                })
            .roundedEditableSection()
             */

            OptionRow(
                action: { isShowingSignOutConfirmation.toggle() },
                height: .tall,
                content: {
                    Text("Sign out")
                        .foregroundColor(.passBrand)
                },
                trailing: {
                    CircleButton(icon: IconProvider.arrowOutFromRectangle,
                                 color: .passBrand,
                                 action: {})
                    .disabled(true)
                })
            .roundedEditableSection()

            OptionRow(
                action: viewModel.deleteAccount,
                height: .tall,
                content: {
                    Text("Delete account")
                        .foregroundColor(.notificationError)
                },
                trailing: {
                    CircleButton(icon: IconProvider.trash,
                                 color: .notificationError,
                                 action: {})
                    .disabled(true)
                })
            .roundedEditableSection()

            // swiftlint:disable:next line_length
            Text("This will permanently delete your account and all of its data. You will not be able to reactivate this account.")
                .sectionTitleText()

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color.passBackground)
        .navigationTitle("Account")
        .navigationBarBackButtonHidden()
        .navigationBarHidden(false)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                CircleButton(icon: UIDevice.current.isIpad ?
                             IconProvider.chevronLeft : IconProvider.chevronDown,
                             color: .passBrand,
                             action: viewModel.goBack)
            }
        }
        .alert(
            "You will be signed out",
            isPresented: $isShowingSignOutConfirmation,
            actions: {
                Button(role: .destructive,
                       action: viewModel.signOut,
                       label: { Text("Yes, sign me out") })

                Button(role: .cancel, label: { Text("Cancel") })
            })
    }
}
