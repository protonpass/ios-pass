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

import DesignSystem
import Macro
import ProtonCoreUIFoundations
import SwiftUI

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

    @ViewBuilder
    private var realBody: some View {
        ScrollView {
            VStack {
                VStack(spacing: 0) {
                    OptionRow(title: #localized("Username"),
                              height: .tall,
                              content: {
                                  Text(viewModel.username)
                                      .foregroundColor(Color(uiColor: PassColor.textNorm))
                              })

                    if let plan = viewModel.plan {
                        PassSectionDivider()

                        OptionRow(title: #localized("Subscription plan"),
                                  height: .tall,
                                  content: {
                                      Text(plan.displayName)
                                          .foregroundColor(PassColor.textNorm.toColor)
                                  })
                    }
                }
                .roundedEditableSection()

                VStack(spacing: 0) {
                    OptionRow(action: { viewModel.openAccountSettings() },
                              height: .tall,
                              content: {
                                  Text("Manage account")
                                      .foregroundColor(PassColor.interactionNormMajor2.toColor)
                              },
                              trailing: {
                                  CircleButton(icon: IconProvider.arrowOutSquare,
                                               iconColor: PassColor.interactionNormMajor2,
                                               backgroundColor: PassColor.interactionNormMinor1)
                              })

                    PassSectionDivider()

                    OptionRow(action: { viewModel.manageSubscription() },
                              height: .tall,
                              content: {
                                  Text("Manage subscription")
                                      .foregroundColor(PassColor.interactionNormMajor2.toColor)
                              },
                              trailing: {
                                  CircleButton(icon: IconProvider.arrowOutSquare,
                                               iconColor: PassColor.interactionNormMajor2,
                                               backgroundColor: PassColor.interactionNormMinor1)
                              })
                }
                .roundedEditableSection()
                .padding(.top)

                OptionRow(action: { isShowingSignOutConfirmation.toggle() },
                          height: .tall,
                          content: {
                              Text("Sign out")
                                  .foregroundColor(PassColor.interactionNormMajor2.toColor)
                          },
                          trailing: {
                              CircleButton(icon: IconProvider.arrowOutFromRectangle,
                                           iconColor: PassColor.interactionNormMajor2,
                                           backgroundColor: PassColor.interactionNormMinor1)
                          })
                          .roundedEditableSection()
                          .padding(.vertical)

                OptionRow(action: { viewModel.deleteAccount() },
                          height: .tall,
                          content: {
                              Text("Delete account")
                                  .foregroundColor(PassColor.signalDanger.toColor)
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
        .background(PassColor.backgroundNorm.toColor)
        .toolbar { toolbarContent }
        .showSpinner(viewModel.isLoading)
        .alert("You will be signed out",
               isPresented: $isShowingSignOutConfirmation,
               actions: {
                   Button(role: .destructive,
                          action: { viewModel.signOut() },
                          label: { Text("Yes, sign me out") })

                   Button(role: .cancel, label: { Text("Cancel") })
               })
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: viewModel.isShownAsSheet ? IconProvider.chevronDown : IconProvider.chevronLeft,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         action: { viewModel.goBack() })
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            if viewModel.plan?.hideUpgrade == false {
                CapsuleLabelButton(icon: PassIcon.brandPass,
                                   title: #localized("Upgrade"),
                                   titleColor: ColorProvider.TextInverted,
                                   backgroundColor: PassColor.interactionNormMajor2,
                                   action: { viewModel.upgradeSubscription() })
            } else {
                EmptyView()
            }
        }
    }
}
