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
    @State private var presentSentinelSheet = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    if viewModel.sentinelEnabled, viewModel.isSentinelEligible {
                        Button { presentSentinelSheet = true } label: {
                            sentinelCell
                                .padding(.horizontal)
                                .padding(.bottom)
                                .showSpinner(viewModel.updatingSentinel)
                        }
                        .buttonStyle(.plain)
                    }
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
                .animation(.default, value: viewModel.isSentinelEligible)
                .showSpinner(viewModel.loading)
            }

            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .background(PassColor.backgroundNorm.toColor)
            .toolbar { toolbarContent }
        }
        .task {
            await viewModel.refreshPlan()
            await viewModel.checkSentinel()
        }
        .sheet(isPresented: $presentSentinelSheet) {
            SentinelSheetView(isPresented: $presentSentinelSheet,
                              sentinelActive: viewModel.isSentinelActive,
                              mainAction: { viewModel.toggleSentinelState()
                                  presentSentinelSheet = false
                              },
                              secondaryAction: { viewModel.showSentinelInformation() })
                .presentationDetents([.height(500)])
        }
        .navigationViewStyle(.stack)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if viewModel.plan?.hideUpgrade == false {
                CapsuleLabelButton(icon: PassIcon.brandPass,
                                   title: #localized("Upgrade"),
                                   titleColor: PassColor.interactionNorm,
                                   backgroundColor: PassColor.interactionNormMinor2,
                                   action: { viewModel.upgrade() })
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
                .padding(.bottom, DesignConstant.sectionPadding)

            VStack(spacing: 0) {
                OptionRow(action: { viewModel.editLocalAuthenticationMethod() },
                          height: .tall,
                          content: {
                              VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 2) {
                                  Text("Unlock with")
                                      .sectionTitleText()

                                  Text(viewModel.localAuthenticationMethod.title)
                                      .foregroundColor(PassColor.textNorm.toColor)
                              }
                          },
                          trailing: { ChevronRight() })

                if viewModel.localAuthenticationMethod != .none {
                    PassDivider()

                    OptionRow(action: { viewModel.editAppLockTime() },
                              height: .tall,
                              content: {
                                  VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 2) {
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
                                .foregroundColor(PassColor.textNorm.toColor)
                        }
                        .tint(PassColor.interactionNorm.toColor)
                    }

                case .pin:
                    PassDivider()

                    OptionRow(action: { viewModel.editPINCode() },
                              height: .medium,
                              content: {
                                  HStack {
                                      Text("Change PIN code")
                                      Spacer()
                                      CircleButton(icon: IconProvider.grid3,
                                                   iconColor: PassColor.interactionNormMajor2,
                                                   backgroundColor: PassColor.interactionNormMinor1,
                                                   action: nil)
                                  }
                                  .foregroundColor(PassColor.interactionNormMajor2.toColor)
                              })
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
                        .foregroundColor(PassColor.textNorm.toColor)

                    Spacer()

                    Button { viewModel.handleEnableAutoFillAction() } label: {
                        Label(ProcessInfo.processInfo.isiOSAppOnMac ? "Show me how" : "Open Settings",
                              systemImage: "arrow.up.right.square")
                            .font(.callout.weight(.semibold))
                            .foregroundColor(PassColor.interactionNormMajor2.toColor)
                    }
                }
            }
            .roundedEditableSection()

            Text("AutoFill on apps and websites by enabling Proton Pass AutoFill")
                .sectionTitleText()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, DesignConstant.sectionPadding / 2)
        }
        .padding(.horizontal)
    }

    private var autoFillEnabledSection: some View {
        VStack {
            VStack(spacing: 0) {
                OptionRow(height: .medium) {
                    Toggle(isOn: $viewModel.quickTypeBar) {
                        Text("QuickType bar suggestions")
                            .foregroundColor(PassColor.textNorm.toColor)
                    }
                    .tint(PassColor.interactionNorm.toColor)
                }

                PassSectionDivider()

                OptionRow(height: .medium) {
                    Toggle(isOn: $viewModel.automaticallyCopyTotpCode) {
                        Text("Copy 2FA code")
                            .foregroundColor(PassColor.textNorm.toColor)
                    }
                    .tint(PassColor.interactionNorm.toColor)
                }
            }
            .roundedEditableSection()
        }
        .padding(.horizontal)
    }

    private var accountAndSettingsSection: some View {
        VStack(spacing: 0) {
            OptionRow(action: { viewModel.showAccountMenu() },
                      content: {
                          HStack {
                              Text("Account")
                                  .foregroundColor(PassColor.textNorm.toColor)

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
                                  .foregroundColor(associatedPlanInfo.tintColor.toColor)
                                  .padding(.horizontal)
                              }
                          }
                      },
                      trailing: { ChevronRight() })

            PassSectionDivider()

            TextOptionRow(title: #localized("Settings"), action: { viewModel.showSettingsMenu() })
        }
        .roundedEditableSection()
        .padding(.horizontal)
    }

    private var aboutSection: some View {
        VStack(spacing: 0) {
            TextOptionRow(title: #localized("Privacy policy"), action: { viewModel.showPrivacyPolicy() })
            PassSectionDivider()
            TextOptionRow(title: #localized("Terms of service"), action: { viewModel.showTermsOfService() })
        }
        .roundedEditableSection()
        .padding(.horizontal)
    }

    private var helpCenterSection: some View {
        VStack(spacing: 0) {
            Text("Help center")
                .profileSectionTitle()
                .padding(.bottom, DesignConstant.sectionPadding)

            VStack(spacing: 0) {
                if Bundle.main.isQaBuild {
                    TextOptionRow(title: "Import to/export from Proton Pass",
                                  action: { viewModel.showImportExportFlow() })
                } else {
                    TextOptionRow(title: #localized("How to import to Proton Pass"),
                                  action: { viewModel.showImportInstructions() })
                }

                PassSectionDivider()
                TextOptionRow(title: #localized("Feedback"), action: { viewModel.showFeedback() })

                PassSectionDivider()
                OptionRow(action: { viewModel.showTutorial() },
                          content: {
                              Text("How to use Proton Pass")
                                  .foregroundColor(PassColor.textNorm.toColor)
                          },
                          trailing: {
                              Image(uiImage: IconProvider.arrowOutSquare)
                                  .resizable()
                                  .scaledToFit()
                                  .frame(height: 16)
                                  .foregroundColor(PassColor.textHint.toColor)
                          })
            }
            .roundedEditableSection()
        }
        .padding(.horizontal)
    }

    private var qaFeaturesSection: some View {
        VStack(spacing: 0) {
            TextOptionRow(title: "QA Features", action: { viewModel.qaFeatures() })
        }
        .roundedEditableSection()
        .padding(.horizontal)
    }
}

// MARK: - Sentinel

private extension ProfileTabView {
    var sentinelCell: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ZStack(alignment: .bottomTrailing) {
                Image(uiImage: PassIcon.sentinelLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40)

                Image(systemName: viewModel.isSentinelActive ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .resizable()
                    .frame(width: 12, height: 12)
                    .foregroundColor(viewModel.isSentinelActive ? PassColor.interactionNormMajor2.toColor :
                        PassColor.noteInteractionNormMajor2.toColor)
                    .background(viewModel.isSentinelActive ? .white : .black)
                    .clipShape(.circle)
            }

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(verbatim: "Proton Sentinel ")
                    .font(.body)
                    .foregroundColor(PassColor.textNorm.toColor)
                    + Text(verbatim: viewModel.isSentinelActive ? #localized("Active") : #localized("Inactive"))
                    .font(.body)
                    .foregroundColor(viewModel.isSentinelActive ? PassColor.interactionNormMajor2
                        .toColor : PassColor.noteInteractionNormMajor2.toColor)
                Text("Increase your security")
                    .font(.footnote)
                    .foregroundColor(PassColor.textWeak.toColor)
            }
            .frame(maxWidth: .infinity, minHeight: 75, alignment: .leading)
            .contentShape(Rectangle())
            ItemDetailSectionIcon(icon: IconProvider.chevronRight,
                                  color: PassColor.textWeak,
                                  width: 15)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .background(PassColor.inputBackgroundNorm.toColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(LinearGradient(gradient:
                Gradient(colors: [
                    PassColor.interactionNormMajor2.toColor,
                    PassColor.noteInteractionNormMajor2.toColor
                ]),
                startPoint: .leading,
                endPoint: .trailing),
            lineWidth: 1))
    }
}

private extension View {
    func profileSectionTitle() -> some View {
        foregroundColor(PassColor.textNorm.toColor)
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

        case .business, .plus:
            .init(title: displayName,
                  icon: PassIcon.badgePaid,
                  iconWidth: 16,
                  tintColor: PassColor.noteInteractionNormMajor2)
        }
    }
}

struct SentinelSheetView: View {
    @Binding var isPresented: Bool
    let sentinelActive: Bool
    let mainAction: () -> Void
    let secondaryAction: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            PassColor.backgroundNorm.toColor
                .ignoresSafeArea()

            ViewThatFits {
                mainSentinelSheet.padding(20)
                ScrollView(showsIndicators: false) {
                    mainSentinelSheet
                }.padding(20)
            }

            Button { isPresented = false } label: {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(PassColor.interactionNormMinor1.toColor)
                    .background(PassColor.interactionNormMajor2.toColor)
                    .clipShape(.circle)
            }
            .buttonStyle(.plain)
            .padding(15)
        }
    }

    private var mainSentinelSheet: some View {
        VStack(spacing: 16) {
            Image(uiImage: PassIcon.netShield)
                .resizable()
                .scaledToFit()

            Text("Proton Sentinel")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Sentinel description")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .top)

            CapsuleTextButton(title: sentinelActive ? #localized("Disable Proton Sentinel") :
                #localized("Enable Proton Sentinel"),
                titleColor: PassColor.interactionNormMinor2,
                backgroundColor: PassColor.interactionNormMajor1,
                action: {
                    mainAction()
                })
                .padding(.horizontal, DesignConstant.sectionPadding)

            CapsuleTextButton(title: #localized("Learn more"),
                              titleColor: PassColor.interactionNormMajor2,
                              backgroundColor: PassColor.interactionNormMinor1,
                              action: { secondaryAction() })
                .padding(.horizontal, DesignConstant.sectionPadding)
        }
    }
}
