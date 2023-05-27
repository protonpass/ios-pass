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
        if viewModel.isShownAsSheet {
            NavigationView {
                realBody
            }
            .navigationViewStyle(.stack)
        } else {
            realBody
        }
    }

    private var realBody: some View {
        ScrollView {
            VStack {
                VStack(spacing: 0) {
                    OptionRow(
                        title: "Username",
                        height: .tall,
                        content: {
                            Text(viewModel.username)
                                .foregroundColor(Color(uiColor: PassColor.textNorm))
                        })

                    if let plan = viewModel.plan {
                        PassSectionDivider()

                        OptionRow(
                            title: "Subscription plan",
                            height: .tall,
                            content: {
                                Text(plan.displayName)
                                    .foregroundColor(Color(uiColor: PassColor.textNorm))
                            })
                    }
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
                            .foregroundColor(Color(uiColor: PassColor.interactionNormMajor2))
                    },
                    trailing: {
                        CircleButton(icon: IconProvider.arrowOutFromRectangle,
                                     iconColor: PassColor.interactionNormMajor2,
                                     backgroundColor: PassColor.interactionNormMinor1)
                    })
                .roundedEditableSection()
                .padding(.vertical)

                OptionRow(
                    action: viewModel.deleteAccount,
                    height: .tall,
                    content: {
                        Text("Delete account")
                            .foregroundColor(Color(uiColor: PassColor.signalDanger))
                    },
                    trailing: {
                        CircleButton(icon: IconProvider.trash,
                                     iconColor: PassColor.signalDanger,
                                     backgroundColor: PassColor.passwordInteractionNormMinor1)
                    })
                .roundedEditableSection()

                // swiftlint:disable:next line_length
                Text("This will permanently delete your Proton account and all of its data, including email, calendars and data stored in Drive. You will not be able to reactivate this account.")
                    .sectionTitleText()

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .animation(.default, value: viewModel.plan)
        }
        .navigationTitle("Account")
        .navigationBarBackButtonHidden()
        .navigationBarHidden(false)
        .navigationBarTitleDisplayMode(.large)
        .background(Color(uiColor: PassColor.backgroundNorm))
        .toolbar { toolbarContent }
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

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(
                icon: viewModel.isShownAsSheet ? IconProvider.chevronDown : IconProvider.chevronLeft,
                iconColor: PassColor.interactionNormMajor2,
                backgroundColor: PassColor.interactionNormMinor1,
                action: viewModel.goBack)
        }
    }
}
