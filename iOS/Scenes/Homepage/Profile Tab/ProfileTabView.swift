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

import SwiftUI
import UIComponents

struct ProfileTabView: View {
    @StateObject var viewModel: ProfileTabViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    itemCountSection

                    biometricAuthenticationSection
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

                    if UserDefaults.standard.bool(forKey: "qa_features") {
                        qaFeaturesSection
                    }

                    Text(viewModel.appVersion)
                        .sectionTitleText()

                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                }
                .padding(.top)
                .animation(.default, value: viewModel.automaticallyCopyTotpCode)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .itemDetailBackground(theme: viewModel.preferences.theme)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
//            .toolbar { toolbarContent }
        }
        .navigationViewStyle(.stack)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if viewModel.primaryPlan == nil {
                CapsuleLabelButton(icon: PassIcon.brandPass,
                                   title: "Upgrade",
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
            ItemCountView(vaultsManager: viewModel.vaultsManager)
        }
    }

    private var biometricAuthenticationSection: some View {
        VStack(spacing: 0) {
            Text("Manage my profile")
                .profileSectionTitle()
                .padding(.bottom, kItemDetailSectionPadding)

            OptionRow(height: .medium) {
                switch viewModel.biometricAuthenticator.biometryTypeState {
                case .idle, .initializing:
                    ProgressView()
                case .initialized(let biometryType):
                    if let uiModel = biometryType.uiModel {
                        Toggle(isOn: $viewModel.biometricAuthenticator.enabled) {
                            Label(title: {
                                Text(uiModel.title)
                                    .foregroundColor(Color(uiColor: PassColor.textNorm))
                            }, icon: {
                                if let icon = uiModel.icon {
                                    Image(systemName: icon)
                                        .foregroundColor(Color(uiColor: PassColor.interactionNorm))
                                } else {
                                    EmptyView()
                                }
                            })
                        }
                        .tint(Color(uiColor: PassColor.interactionNorm))
                    } else {
                        Text("Biometric authentication not supported")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color(uiColor: PassColor.textWeak))
                    }
                case .error(let error):
                    Text(error.localizedDescription)
                        .foregroundColor(Color(uiColor: PassColor.signalDanger))
                }
            }
            .roundedEditableSection()

            if case .initialized(let biometryType) = viewModel.biometricAuthenticator.biometryTypeState,
               biometryType != .none {
                Text("Unlock Proton Pass with a glance")
                    .sectionTitleText()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, kItemDetailSectionPadding / 2)
            }
        }
        .padding(.horizontal)
    }

    private var autoFillDisabledSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("AutoFill disabled")
                    .foregroundColor(Color(uiColor: PassColor.textNorm))

                Spacer()

                Button(action: UIApplication.shared.openPasswordSettings) {
                    Label("Open Settings", systemImage: "arrow.up.right.square")
                        .font(.callout.weight(.semibold))
                        .foregroundColor(Color(uiColor: PassColor.interactionNormMajor2))
                }
            }
            .padding(.horizontal, kItemDetailSectionPadding)
            .frame(height: OptionRowHeight.short.value)
            .roundedEditableSection()

            Text("AutoFill on apps and websites by enabling Proton Pass AutoFill.")
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

            if viewModel.automaticallyCopyTotpCode {
                Text("When autofilling, you will be warned if the 2FA code expires in less than 10 seconds")
                    .sectionTitleText()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal)
    }

    private var accountAndSettingsSection: some View {
        VStack(spacing: 0) {
            TextOptionRow(title: "Account", action: viewModel.showAccountMenu)
            PassSectionDivider()
            TextOptionRow(title: "Settings", action: viewModel.showSettingsMenu)
        }
        .roundedEditableSection()
        .padding(.horizontal)
    }

    private var aboutSection: some View {
        VStack(spacing: 0) {
            /*
             TextOptionRow(title: "Acknowledgments", action: viewModel.showAcknowledgments)
             PassSectionDivider()
             */
            TextOptionRow(title: "Privacy policy", action: viewModel.showPrivacyPolicy)
            PassSectionDivider()
            TextOptionRow(title: "Terms of service", action: viewModel.showTermsOfService)
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
                /*
                TextOptionRow(title: "Tips", action: viewModel.showTips)
                 PassSectionDivider()
                 */
                TextOptionRow(title: "Feedback", action: viewModel.showFeedback)
                PassSectionDivider()
                TextOptionRow(title: "Rate app", action: viewModel.rateApp)
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
        self.foregroundColor(Color(uiColor: PassColor.textNorm))
            .font(.callout.weight(.bold))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
