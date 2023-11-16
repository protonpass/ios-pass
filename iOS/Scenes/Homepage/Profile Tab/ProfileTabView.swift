//
// ProfileTabView.swift
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

import Core
import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct ProfileTabView: View {
    @StateObject var viewModel: ProfileTabViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    itemCountSection

                    securitySection
                        .padding(.vertical)

                    if viewModel.autoFillEnabled {
                        autoFillEnabledSection
                    } else {
                        autoFillDisabledSection
                    }

                    accountAndSettingsSection
                        .padding(.vertical)

                    aboutSection

                    helpCenterSection
                        .padding(.vertical)

                    if Bundle.main.isQaBuild {
                        qaFeaturesSection
                    }

                    Text("Version \(Bundle.main.displayedAppVersion)")
                        .sectionTitleText()

                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                }
                .padding(.top)
                .animation(.default, value: viewModel.automaticallyCopyTotpCode)
                .animation(.default, value: viewModel.localAuthenticationMethod)
                .showSpinner(viewModel.loading)
            }

            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(uiColor: PassColor.backgroundNorm))
            .toolbar { toolbarContent }
        }
        .task {
            await viewModel.refreshPlan()
        }
        .navigationViewStyle(.stack)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if let plan = viewModel.plan, plan.planType != .plus {
                CapsuleLabelButton(icon: PassIcon.brandPass,
                                   title: #localized("Upgrade"),
                                   titleColor: PassColor.interactionNorm,
                                   backgroundColor: PassColor.interactionNormMinor2,
                                   action: viewModel.upgrade)
            } else {
                EmptyView()
            }
        }
    }

    private var itemCountSection: some View {
        VStack {
            Text("Items")
                .profileSectionTitle()
                .padding(.horizontal)
            ItemCountView()
        }
    }

    private var securitySection: some View {
        VStack(spacing: 0) {
            Text("Security")
                .profileSectionTitle()
                .padding(.bottom, kItemDetailSectionPadding)

            VStack(spacing: 0) {
                OptionRow(action: viewModel.editLocalAuthenticationMethod,
                          height: .tall,
                          content: {
                              VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 2) {
                                  Text("Unlock with")
                                      .sectionTitleText()

                                  Text(viewModel.localAuthenticationMethod.title)
                                      .foregroundColor(PassColor.textNorm.toColor)
                              }
                          },
                          trailing: { ChevronRight() })

                if viewModel.localAuthenticationMethod != .none {
                    PassDivider()

                    OptionRow(action: viewModel.editAppLockTime,
                              height: .tall,
                              content: {
                                  VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 2) {
                                      Text("Automatic lock")
                                          .sectionTitleText()

                                      Text(viewModel.appLockTime.description)
                                          .foregroundColor(PassColor.textNorm.toColor)
                                  }
                              },
                              trailing: { ChevronRight() })
                }

                switch viewModel.localAuthenticationMethod {
                case .none:
                    EmptyView()

                case let .biometric(type):
                    PassDivider()

                    OptionRow(height: .tall) {
                        Toggle(isOn: $viewModel.fallbackToPasscode) {
                            Text(type.fallbackToPasscodeMessage)
                                .foregroundColor(Color(uiColor: PassColor.textNorm))
                        }
                        .tint(Color(uiColor: PassColor.interactionNorm))
                    }

                case .pin:
                    PassDivider()

                    OptionRow(action: viewModel.editPINCode, height: .medium) {
                        HStack {
                            Text("Change PIN code")
                            Spacer()
                            CircleButton(icon: IconProvider.grid3,
                                         iconColor: PassColor.interactionNormMajor2,
                                         backgroundColor: PassColor.interactionNormMinor1,
                                         action: nil)
                        }
                        .foregroundColor(PassColor.interactionNormMajor2.toColor)
                    }
                }
            }
            .roundedEditableSection()
        }
        .padding(.horizontal)
    }

    private var autoFillDisabledSection: some View {
        VStack(spacing: 0) {
            OptionRow(height: .medium) {
                HStack {
                    Text("AutoFill disabled")
                        .foregroundColor(Color(uiColor: PassColor.textNorm))

                    Spacer()

                    if ProcessInfo.processInfo.isiOSAppOnMac {
                        Button(action: viewModel.showEnableAutoFillOnMacInstructions) {
                            Label("Show me how", systemImage: "arrow.up.right.square")
                                .font(.callout.weight(.semibold))
                                .foregroundColor(PassColor.interactionNormMajor2.toColor)
                        }
                    } else {
                        Button(action: UIApplication.shared.openPasswordSettings) {
                            Label("Open Settings", systemImage: "arrow.up.right.square")
                                .font(.callout.weight(.semibold))
                                .foregroundColor(PassColor.interactionNormMajor2.toColor)
                        }
                    }
                }
            }
            .roundedEditableSection()

            Text("AutoFill on apps and websites by enabling Proton Pass AutoFill")
                .sectionTitleText()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, kItemDetailSectionPadding / 2)
        }
        .padding(.horizontal)
    }

    private var autoFillEnabledSection: some View {
        VStack {
            VStack(spacing: 0) {
                OptionRow(height: .medium) {
                    Toggle(isOn: $viewModel.quickTypeBar) {
                        Text("QuickType bar suggestions")
                            .foregroundColor(Color(uiColor: PassColor.textNorm))
                    }
                    .tint(Color(uiColor: PassColor.interactionNorm))
                }

                PassSectionDivider()

                OptionRow(height: .medium) {
                    Toggle(isOn: $viewModel.automaticallyCopyTotpCode) {
                        Text("Copy 2FA code")
                            .foregroundColor(Color(uiColor: PassColor.textNorm))
                    }
                    .tint(Color(uiColor: PassColor.interactionNorm))
                }
            }
            .roundedEditableSection()
        }
        .padding(.horizontal)
    }

    private var accountAndSettingsSection: some View {
        VStack(spacing: 0) {
            OptionRow(action: viewModel.showAccountMenu,
                      content: {
                          HStack {
                              Text("Account")
                                  .foregroundColor(Color(uiColor: PassColor.textNorm))

                              Spacer()

                              if let associatedPlanInfo = viewModel.plan?.associatedPlanInfo {
                                  Label(title: {
                                      Text(associatedPlanInfo.title)
                                          .font(.callout)
                                  }, icon: {
                                      Image(uiImage: associatedPlanInfo.icon)
                                          .resizable()
                                          .scaledToFit()
                                          .frame(maxWidth: associatedPlanInfo.iconWidth)
                                  })
                                  .foregroundColor(Color(uiColor: associatedPlanInfo.tintColor))
                                  .padding(.horizontal)
                              }
                          }
                      },
                      trailing: { ChevronRight() })

            PassSectionDivider()

            TextOptionRow(title: #localized("Settings"), action: viewModel.showSettingsMenu)
        }
        .roundedEditableSection()
        .padding(.horizontal)
    }

    private var aboutSection: some View {
        VStack(spacing: 0) {
            TextOptionRow(title: #localized("Privacy policy"), action: viewModel.showPrivacyPolicy)
            PassSectionDivider()
            TextOptionRow(title: #localized("Terms of service"), action: viewModel.showTermsOfService)
        }
        .roundedEditableSection()
        .padding(.horizontal)
    }

    private var helpCenterSection: some View {
        VStack(spacing: 0) {
            Text("Help center")
                .profileSectionTitle()
                .padding(.bottom, kItemDetailSectionPadding)

            VStack(spacing: 0) {
                TextOptionRow(title: #localized("How to import to Proton Pass"),
                              action: viewModel.showImportInstructions)
                PassSectionDivider()
                TextOptionRow(title: #localized("Feedback"), action: viewModel.showFeedback)
            }
            .roundedEditableSection()
        }
        .padding(.horizontal)
    }

    private var qaFeaturesSection: some View {
        VStack(spacing: 0) {
            TextOptionRow(title: "QA Features", action: viewModel.qaFeatures)
        }
        .roundedEditableSection()
        .padding(.horizontal)
    }
}

private extension View {
    func profileSectionTitle() -> some View {
        foregroundColor(Color(uiColor: PassColor.textNorm))
            .font(.callout.weight(.bold))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AssociatedPlanInfo {
    let title: String
    let icon: UIImage
    let iconWidth: CGFloat
    let tintColor: UIColor
}

private extension Plan {
    var associatedPlanInfo: AssociatedPlanInfo? {
        switch planType {
        case .free:
            nil

        case .trial:
            .init(title: #localized("Free trial"),
                  icon: PassIcon.badgeTrial,
                  iconWidth: 12,
                  tintColor: PassColor.interactionNormMajor2)

        case .plus:
            .init(title: displayName,
                  icon: PassIcon.badgePaid,
                  iconWidth: 16,
                  tintColor: PassColor.noteInteractionNormMajor2)
        }
    }
}
