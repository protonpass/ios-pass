//
//
// IdentityDetailView.swift
// Proton Pass - Created on 27/05/2024.
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

import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct IdentityDetailView: View {
    @StateObject private var viewModel: IdentityDetailViewModel
    @Namespace private var bottomID

    init(viewModel: IdentityDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        mainContainer
            .if(viewModel.isShownAsSheet) { view in
                view.navigationStackEmbeded()
            }
    }
}

private extension IdentityDetailView {
    var mainContainer: some View {
        VStack {
            ScrollViewReader { value in
                ScrollView {
                    VStack(spacing: 0) {
                        ItemDetailTitleView(itemContent: viewModel.itemContent,
                                            vault: viewModel.vault?.vault,
                                            shouldShowVault: viewModel.shouldShowVault)
                            .padding(.bottom, 40)

                        personalDetailSection
                        addressDetailSection
                        contactDetailSection
//                        if !viewModel.passkeys.isEmpty {
//                            ForEach(viewModel.passkeys, id: \.keyID) { passkey in
//                                PasskeyDetailRow(passkey: passkey,
//                                                 onTap: { viewModel.viewPasskey(passkey) })
//                                    .padding(.bottom, 8)
//                            }
//                        }

//                        usernamePassword2FaSection

//                        if !viewModel.urls.isEmpty {
//                            urlsSection
//                                .padding(.top, 8)
//                        }
//
//                        if !viewModel.itemContent.note.isEmpty {
//                            NoteDetailSection(itemContent: viewModel.itemContent,
//                                              vault: viewModel.vault?.vault)
//                                .padding(.top, 8)
//                        }

//                        CustomFieldSections(itemContentType: viewModel.itemContent.type,
//                                            uiModels: viewModel.customFieldUiModels,
//                                            isFreeUser: viewModel.isFreeUser,
//                                            onSelectHiddenText: { copyHiddenText($0) },
//                                            onSelectTotpToken: { copyTOTPToken($0) },
//                                            onUpgrade: { viewModel.upgrade() })

                        ItemDetailHistorySection(itemContent: viewModel.itemContent,
                                                 action: { viewModel.showItemHistory() })

                        ItemDetailMoreInfoSection(isExpanded: $viewModel.moreInfoSectionExpanded,
                                                  itemContent: viewModel.itemContent,
                                                  onCopy: { viewModel.copyToClipboard(text: $0, message: $1) })
                            .padding(.top, 24)
                            .id(bottomID)
                    }
                    .padding()
                }
                .animation(.default, value: viewModel.moreInfoSectionExpanded)
                .onChange(of: viewModel.moreInfoSectionExpanded) { _ in
                    withAnimation { value.scrollTo(bottomID, anchor: .bottom) }
                }
            }
        }
        .animation(.default, value: viewModel.moreInfoSectionExpanded)
        .itemDetailSetUp(viewModel)
    }
}

private extension IdentityDetailView {
    var personalDetailSection: some View {
        Section {
            VStack(alignment: .leading) {
                VStack(spacing: DesignConstant.sectionPadding) {
                    if !viewModel.firstName.isEmpty {
                        row(title: "First name", value: viewModel.firstName) {
                            viewModel.copyValueToClipboard(value: viewModel.firstName,
                                                           message: #localized("First name copied"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.middleName.isEmpty {
                        row(title: "Middle name", value: viewModel.middleName) {
                            viewModel.copyValueToClipboard(value: viewModel.middleName,
                                                           message: #localized("Middle name copied"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.lastName.isEmpty {
                        row(title: "Last name", value: viewModel.lastName) {
                            viewModel.copyValueToClipboard(value: viewModel.lastName,
                                                           message: #localized("Last name copied"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.fullName.isEmpty {
                        row(title: "Full name", value: viewModel.fullName) {
                            viewModel.copyValueToClipboard(value: viewModel.fullName,
                                                           message: #localized("Full name copied"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.email.isEmpty {
                        row(title: "Email", value: viewModel.email) {
                            viewModel.copyValueToClipboard(value: viewModel.email,
                                                           message: #localized("Email copied"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.phoneNumber.isEmpty {
                        row(title: "Phone number", value: viewModel.phoneNumber) {
                            viewModel.copyValueToClipboard(value: viewModel.phoneNumber,
                                                           message: #localized("Phone number copied"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.birthdate.isEmpty {
                        row(title: "Birthdate", value: viewModel.birthdate) {
                            viewModel.copyValueToClipboard(value: viewModel.birthdate,
                                                           message: #localized("Birthdate copied"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.gender.isEmpty {
                        row(title: "Gender", value: viewModel.gender) {
                            viewModel.copyValueToClipboard(value: viewModel.gender,
                                                           message: #localized("Gender copied"))
                        }
                        PassSectionDivider()
                    }

                    CustomFieldSections(itemContentType: viewModel.itemContent.type,
                                        uiModels: viewModel.extraPersonalDetails,
                                        isFreeUser: viewModel.isFreeUser,
                                        onSelectHiddenText: { viewModel.copyHiddenText($0) },
                                        onSelectTotpToken: { viewModel.copyTotpToken($0) },
                                        onUpgrade: { viewModel.upgrade() })
                }
                .padding(.vertical, DesignConstant.sectionPadding)
                .roundedEditableSection()
            }
        } header: {
            Text("Personal details")
                .foregroundStyle(PassColor.textWeak.toColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, DesignConstant.sectionPadding)
        }
    }
}

private extension IdentityDetailView {
    var addressDetailSection: some View {
        Section {
            VStack(alignment: .leading) {
                VStack(spacing: DesignConstant.sectionPadding) {
                    if !viewModel.organization.isEmpty {
                        row(title: "Organization", value: viewModel.organization) {
                            viewModel.copyValueToClipboard(value: viewModel.organization,
                                                           message: #localized("Organization copied"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.streetAddress.isEmpty {
                        row(title: "Street address, P.O. box", value: viewModel.streetAddress) {
                            viewModel.copyValueToClipboard(value: viewModel.streetAddress,
                                                           message: #localized("Street address, P.O. box copied"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.zipOrPostalCode.isEmpty {
                        row(title: "ZIP or Postal code", value: viewModel.zipOrPostalCode) {
                            viewModel.copyValueToClipboard(value: viewModel.zipOrPostalCode,
                                                           message: #localized("ZIP or Postal code copied"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.city.isEmpty {
                        row(title: "City", value: viewModel.city) {
                            viewModel.copyValueToClipboard(value: viewModel.city,
                                                           message: #localized("City copied"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.stateOrProvince.isEmpty {
                        row(title: "State or province", value: viewModel.stateOrProvince) {
                            viewModel.copyValueToClipboard(value: viewModel.stateOrProvince,
                                                           message: #localized("State or province copied"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.countryOrRegion.isEmpty {
                        row(title: "Country or Region", value: viewModel.countryOrRegion) {
                            viewModel.copyValueToClipboard(value: viewModel.countryOrRegion,
                                                           message: #localized("Country or Region copied"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.floor.isEmpty {
                        row(title: "Floor", value: viewModel.floor) {
                            viewModel.copyValueToClipboard(value: viewModel.floor,
                                                           message: #localized("Floor copied"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.county.isEmpty {
                        row(title: "County", value: viewModel.county) {
                            viewModel.copyValueToClipboard(value: viewModel.county,
                                                           message: #localized("County copied"))
                        }
                        PassSectionDivider()
                    }

                    CustomFieldSections(itemContentType: viewModel.itemContent.type,
                                        uiModels: viewModel.extraAddressDetails,
                                        isFreeUser: viewModel.isFreeUser,
                                        onSelectHiddenText: { viewModel.copyHiddenText($0) },
                                        onSelectTotpToken: { viewModel.copyTotpToken($0) },
                                        onUpgrade: { viewModel.upgrade() })
                }
                .padding(.vertical, DesignConstant.sectionPadding)
                .roundedEditableSection()
            }
        } header: {
            Text("Address details")
                .foregroundStyle(PassColor.textWeak.toColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, DesignConstant.sectionPadding)
        }
    }
}

private extension IdentityDetailView {
    var contactDetailSection: some View {
        Section {
            VStack(alignment: .leading) {
                VStack(spacing: DesignConstant.sectionPadding) {
                    if !viewModel.socialSecurityNumber.isEmpty {
                        row(title: "Social security number", value: viewModel.socialSecurityNumber) {
                            viewModel.copyValueToClipboard(value: viewModel.socialSecurityNumber,
                                                           message: #localized("Social security number copied"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.passportNumber.isEmpty {
                        row(title: "Passport number", value: viewModel.passportNumber) {
                            viewModel.copyValueToClipboard(value: viewModel.passportNumber,
                                                           message: #localized("Passport number copied"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.licenseNumber.isEmpty {
                        row(title: "License number", value: viewModel.licenseNumber) {
                            viewModel.copyValueToClipboard(value: viewModel.licenseNumber,
                                                           message: #localized("License number copied"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.website.isEmpty {
                        row(title: "Website", value: viewModel.website) {
                            viewModel.copyValueToClipboard(value: viewModel.website,
                                                           message: #localized("Website copied"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.xHandle.isEmpty {
                        row(title: "X handle", value: viewModel.xHandle) {
                            viewModel.copyValueToClipboard(value: viewModel.xHandle,
                                                           message: #localized("X handle copied"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.secondPhoneNumber.isEmpty {
                        row(title: "Second phone number", value: viewModel.secondPhoneNumber) {
                            viewModel.copyValueToClipboard(value: viewModel.secondPhoneNumber,
                                                           message: #localized("Second phone number copied"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.linkedin.isEmpty {
                        row(title: "Linkedin", value: viewModel.linkedin) {
                            viewModel.copyValueToClipboard(value: viewModel.linkedin,
                                                           message: #localized("Linkedin copied"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.reddit.isEmpty {
                        row(title: "Reddit", value: viewModel.reddit) {
                            viewModel.copyValueToClipboard(value: viewModel.reddit,
                                                           message: #localized("Reddit copied"))
                        }
                        PassSectionDivider()
                    }

                    if !viewModel.facebook.isEmpty {
                        row(title: "Facebook", value: viewModel.facebook) {
                            viewModel.copyValueToClipboard(value: viewModel.facebook,
                                                           message: #localized("Facebook copied"))
                        }
                        PassSectionDivider()
                    }

                    if !viewModel.yahoo.isEmpty {
                        row(title: "Yahoo", value: viewModel.yahoo) {
                            viewModel.copyValueToClipboard(value: viewModel.yahoo,
                                                           message: #localized("Yahoo copied"))
                        }
                        PassSectionDivider()
                    }

                    if !viewModel.instagram.isEmpty {
                        row(title: "Instagram", value: viewModel.instagram) {
                            viewModel.copyValueToClipboard(value: viewModel.instagram,
                                                           message: #localized("Instagram copied"))
                        }
                        PassSectionDivider()
                    }

                    CustomFieldSections(itemContentType: viewModel.itemContent.type,
                                        uiModels: viewModel.extraContactDetails,
                                        isFreeUser: viewModel.isFreeUser,
                                        onSelectHiddenText: { viewModel.copyHiddenText($0) },
                                        onSelectTotpToken: { viewModel.copyTotpToken($0) },
                                        onUpgrade: { viewModel.upgrade() })
                }
                .padding(.vertical, DesignConstant.sectionPadding)
                .roundedEditableSection()
            }
        } header: {
            Text("Contact details")
                .foregroundStyle(PassColor.textWeak.toColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, DesignConstant.sectionPadding)
        }
    }
}

private extension IdentityDetailView {
    func row(title: String, value: String, onTap: @escaping () -> Void) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(title)
                    .sectionTitleText()
                Text(value)
                    .sectionContentText()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture(perform: onTap)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .contextMenu {
            Button(action: onTap) {
                Text("Copy")
            }

//            Button {
//                viewModel.showLarge(.text(viewModel.username))
//            } label: {
//                Text("Show large")
//            }
        }
    }
}

//
// struct LogInDetailView: View {
//    @StateObject private var viewModel: LogInDetailViewModel
//    @State private var isShowingPassword = false
//    @Namespace private var bottomID
//
//    private var iconTintColor: UIColor { viewModel.itemContent.type.normColor }
//
//    init(viewModel: LogInDetailViewModel) {
//        _viewModel = .init(wrappedValue: viewModel)
//    }
//
//    var body: some View {
//        if viewModel.isShownAsSheet {
//            NavigationStack {
//                realBody
//            }
//        } else {
//            realBody
//        }
//    }
// }

// private extension LogInDetailView {
//    var realBody: some View {
//        VStack {
//            ScrollViewReader { value in
//                ScrollView {
//                    VStack(spacing: 0) {
//                        if viewModel.showSecurityIssues, let issues = viewModel.securityIssues {
//                            securityIssuesView(issues: issues)
//                                .padding(.vertical)
//                        }
//
//                        ItemDetailTitleView(itemContent: viewModel.itemContent,
//                                            vault: viewModel.vault?.vault,
//                                            shouldShowVault: viewModel.shouldShowVault)
//                            .padding(.bottom, 40)
//
//                        if !viewModel.passkeys.isEmpty {
//                            ForEach(viewModel.passkeys, id: \.keyID) { passkey in
//                                PasskeyDetailRow(passkey: passkey,
//                                                 onTap: { viewModel.viewPasskey(passkey) })
//                                    .padding(.bottom, 8)
//                            }
//                        }
//
//                        usernamePassword2FaSection
//
//                        if !viewModel.urls.isEmpty {
//                            urlsSection
//                                .padding(.top, 8)
//                        }
//
//                        if !viewModel.itemContent.note.isEmpty {
//                            NoteDetailSection(itemContent: viewModel.itemContent,
//                                              vault: viewModel.vault?.vault)
//                                .padding(.top, 8)
//                        }
//
//                        CustomFieldSections(itemContentType: viewModel.itemContent.type,
//                                            uiModels: viewModel.customFieldUiModels,
//                                            isFreeUser: viewModel.isFreeUser,
//                                            onSelectHiddenText: { copyHiddenText($0) },
//                                            onSelectTotpToken: { copyTOTPToken($0) },
//                                            onUpgrade: { viewModel.upgrade() })
//
//                        ItemDetailHistorySection(itemContent: viewModel.itemContent,
//                                                 action: { viewModel.showItemHistory() })
//
//                        ItemDetailMoreInfoSection(isExpanded: $viewModel.moreInfoSectionExpanded,
//                                                  itemContent: viewModel.itemContent,
//                                                  onCopy: { viewModel.copyToClipboard(text: $0, message: $1) })
//                            .padding(.top, 24)
//                            .id(bottomID)
//                    }
//                    .padding()
//                }
//                .animation(.default, value: viewModel.moreInfoSectionExpanded)
//                .onChange(of: viewModel.moreInfoSectionExpanded) { _ in
//                    withAnimation { value.scrollTo(bottomID, anchor: .bottom) }
//                }
//            }
//
//            if viewModel.isAlias {
//                viewAliasCard
//                    .padding(.horizontal)
//            }
//        }
//        .animation(.default, value: viewModel.moreInfoSectionExpanded)
//        .itemDetailSetUp(viewModel)
//    }
// }
//
//
//
//
//
// private extension LogInDetailView {
//    var usernamePassword2FaSection: some View {
//        VStack(spacing: DesignConstant.sectionPadding) {
//            emailRow
//            PassSectionDivider()
//            if !viewModel.username.isEmpty {
//                usernameRow
//                PassSectionDivider()
//            }
//            passwordRow
//
//            switch viewModel.totpTokenState {
//            case .loading:
//                EmptyView()
//
//            case .notAllowed:
//                PassSectionDivider()
//                totpNotAllowedRow
//
//            case .allowed:
//                if viewModel.totpUri.isEmpty {
//                    EmptyView()
//                } else {
//                    PassSectionDivider()
//                    TOTPRow(uri: viewModel.totpUri,
//                            tintColor: iconTintColor,
//                            onCopyTotpToken: { viewModel.copyTotpToken($0) })
//                }
//            }
//        }
//        .padding(.vertical, DesignConstant.sectionPadding)
//        .roundedDetailSection()
//        .animation(.default, value: viewModel.totpTokenState)
//    }
//
//    var emailRow: some View {
//        HStack(spacing: DesignConstant.sectionPadding) {
//            ItemDetailSectionIcon(icon: viewModel.isAlias ? IconProvider.alias : IconProvider.envelope,
//                                  color: iconTintColor)
//
//            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
//                Text("Email address")
//                    .sectionTitleText()
//
//                if viewModel.email.isEmpty {
//                    Text("Empty")
//                        .placeholderText()
//                } else {
//                    Text(viewModel.email)
//                        .sectionContentText()
//
//                    if viewModel.isAlias {
//                        Button { viewModel.showAliasDetail() } label: {
//                            Text("View alias")
//                                .font(.callout)
//                                .foregroundStyle(viewModel.itemContent.type.normMajor2Color.toColor)
//                                .underline(color: viewModel.itemContent.type.normMajor2Color.toColor)
//                        }
//                        .padding(.top, 8)
//                    }
//                }
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .contentShape(.rect)
//            .onTapGesture(perform: { viewModel.copyEmail() })
//        }
//        .padding(.horizontal, DesignConstant.sectionPadding)
//        .contextMenu {
//            Button { viewModel.copyEmail() } label: {
//                Text("Copy")
//            }
//
//            Button {
//                viewModel.showLarge(.text(viewModel.email))
//            } label: {
//                Text("Show large")
//            }
//        }
//    }
//
//    var usernameRow: some View {
//        HStack(spacing: DesignConstant.sectionPadding) {
//            ItemDetailSectionIcon(icon: viewModel.isAlias ? IconProvider.alias : IconProvider.user,
//                                  color: iconTintColor)
//
//            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
//                Text("Username")
//                    .sectionTitleText()
//
//                if viewModel.username.isEmpty {
//                    Text("Empty")
//                        .placeholderText()
//                } else {
//                    Text(viewModel.username)
//                        .sectionContentText()
//
//                    if viewModel.isAlias {
//                        Button { viewModel.showAliasDetail() } label: {
//                            Text("View alias")
//                                .font(.callout)
//                                .foregroundStyle(viewModel.itemContent.type.normMajor2Color.toColor)
//                                .underline(color: viewModel.itemContent.type.normMajor2Color.toColor)
//                        }
//                        .padding(.top, 8)
//                    }
//                }
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .contentShape(.rect)
//            .onTapGesture(perform: { viewModel.copyItemUsername() })
//        }
//        .padding(.horizontal, DesignConstant.sectionPadding)
//        .contextMenu {
//            Button { viewModel.copyItemUsername() } label: {
//                Text("Copy")
//            }
//
//            Button {
//                viewModel.showLarge(.text(viewModel.username))
//            } label: {
//                Text("Show large")
//            }
//        }
//    }
//
//    var passwordRow: some View {
//        HStack(spacing: DesignConstant.sectionPadding) {
//            if let passwordStrength = viewModel.passwordStrength {
//                PasswordStrengthIcon(strength: passwordStrength)
//            } else {
//                ItemDetailSectionIcon(icon: IconProvider.key, color: iconTintColor)
//            }
//
//            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
//                Text(viewModel.passwordStrength.sectionTitle(reuseCount: viewModel.reusedItems?.count))
//                    .font(.footnote)
//                    .foregroundStyle(viewModel.passwordStrength.sectionTitleColor)
//
//                if viewModel.password.isEmpty {
//                    Text("Empty")
//                        .placeholderText()
//                } else {
//                    if isShowingPassword {
//                        Text(viewModel.coloredPassword)
//                            .font(.body.monospaced())
//                    } else {
//                        Text(String(repeating: "•", count: 12))
//                            .sectionContentText()
//                    }
//                }
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .contentShape(.rect)
//            .onTapGesture { viewModel.copyPassword() }
//
//            Spacer()
//
//            if !viewModel.password.isEmpty {
//                CircleButton(icon: isShowingPassword ? IconProvider.eyeSlash : IconProvider.eye,
//                             iconColor: viewModel.itemContent.type.normMajor2Color,
//                             backgroundColor: viewModel.itemContent.type.normMinor2Color,
//                             accessibilityLabel: isShowingPassword ? "Hide password" : "Show password",
//                             action: { isShowingPassword.toggle() })
//                    .fixedSize(horizontal: true, vertical: true)
//                    .animationsDisabled()
//            }
//        }
//        .padding(.horizontal, DesignConstant.sectionPadding)
//        .contextMenu {
//            Button(action: {
//                withAnimation {
//                    isShowingPassword.toggle()
//                }
//            }, label: {
//                Text(isShowingPassword ? "Conceal" : "Reveal")
//            })
//
//            Button { viewModel.copyPassword() } label: {
//                Text("Copy")
//            }
//
//            Button { viewModel.showLargePassword() } label: {
//                Text("Show large")
//            }
//        }
//    }
// }
//
// private extension LogInDetailView {
//    var totpNotAllowedRow: some View {
//        HStack(spacing: DesignConstant.sectionPadding) {
//            ItemDetailSectionIcon(icon: IconProvider.lock, color: iconTintColor)
//
//            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
//                Text("2FA limit reached")
//                    .sectionTitleText()
//                UpgradeButtonLite { viewModel.upgrade() }
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//        }
//        .padding(.horizontal, DesignConstant.sectionPadding)
//    }
//
//    var urlsSection: some View {
//        HStack(spacing: DesignConstant.sectionPadding) {
//            ItemDetailSectionIcon(icon: IconProvider.earth, color: iconTintColor)
//
//            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
//                Text("Website")
//                    .sectionTitleText()
//
//                VStack(alignment: .leading, spacing: 12) {
//                    ForEach(viewModel.urls, id: \.self) { url in
//                        Button(action: {
//                            viewModel.openUrl(url)
//                        }, label: {
//                            Text(url)
//                                .foregroundStyle(viewModel.itemContent.type.normMajor2Color.toColor)
//                                .multilineTextAlignment(.leading)
//                                .lineLimit(2)
//                        })
//                        .contextMenu {
//                            Button(action: {
//                                viewModel.openUrl(url)
//                            }, label: {
//                                Text("Open")
//                            })
//
//                            Button(action: {
//                                viewModel.copyToClipboard(text: url, message: #localized("Website copied"))
//                            }, label: {
//                                Text("Copy")
//                            })
//                        }
//                    }
//                }
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .animation(.default, value: viewModel.urls)
//        }
//        .padding(DesignConstant.sectionPadding)
//        .roundedDetailSection()
//    }
//
//    var viewAliasCard: some View {
//        Group {
//            Text("View and edit details for this alias on the separate alias page.")
//                .font(.callout)
//                .adaptiveForegroundStyle(PassColor.textNorm.toColor) +
//                Text(verbatim: " ")
//                .font(.callout) +
//                Text("View")
//                .font(.callout)
//                .adaptiveForegroundStyle(viewModel.itemContent.type.normMajor2Color.toColor)
//                .underline(color: viewModel.itemContent.type.normMajor2Color.toColor)
//        }
//        .padding(DesignConstant.sectionPadding)
//        .background(PassColor.backgroundMedium.toColor)
//        .clipShape(RoundedRectangle(cornerRadius: 16))
//        .onTapGesture(perform: viewModel.showAliasDetail)
//    }
// }
//
// private extension LogInDetailView {
//    func copyTOTPToken(_ token: String) {
//        viewModel.copyToClipboard(text: token, message: #localized("TOTP copied"))
//    }
//
//    func copyHiddenText(_ text: String) {
//        viewModel.copyToClipboard(text: text, message: #localized("Hidden text copied"))
//    }
// }
//
// private extension LogInDetailView {
//    func securityIssuesView(issues: [SecurityWeakness]) -> some View {
//        VStack {
//            ForEach(issues, id: \.self) {
//                securityWeaknessRow(weakness: $0)
//            }
//        }
//    }
//
//    @ViewBuilder
//    func securityWeaknessRow(weakness: SecurityWeakness) -> some View {
//        let rowType = weakness.secureRowType
//        HStack(spacing: DesignConstant.sectionPadding) {
//            if let iconName = rowType.detailIcon {
//                VStack {
//                    Image(systemName: iconName)
//                        .resizable()
//                        .renderingMode(.template)
//                        .scaledToFit()
//                        .symbolRenderingMode(.hierarchical)
//                        .foregroundStyle(rowType.iconColor.toColor)
//                        .frame(width: 28)
//                        .clipShape(RoundedRectangle(cornerRadius: 8))
//                    Spacer()
//                }
//            }
//
//            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
//                if let title = weakness.detailTitle {
//                    Text(title)
//                        .fontWeight(.bold)
//                        .foregroundStyle(rowType.iconColor.toColor)
//                }
//                if weakness == .reusedPasswords {
//                    reusedList(rowType: rowType)
//                        .padding(.vertical, DesignConstant.sectionPadding / 4)
//                }
//                if let infos = weakness.infos {
//                    Text(infos)
//                        .font(.callout)
//                        .foregroundStyle(rowType.iconColor.toColor)
//                }
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//        }
//        .padding(DesignConstant.sectionPadding)
//        .roundedDetailSection(backgroundColor: rowType.detailBackground,
//                              borderColor: rowType.border)
//    }
//
//    @ViewBuilder
//    func reusedList(rowType: SecureRowType) -> some View {
//        if let reusedItems = viewModel.reusedItems, !reusedItems.isEmpty {
//            let reuseText: () -> Text = {
//                Text("\(reusedItems.count) other logins use this password")
//                    .fontWeight(.bold)
//                    .adaptiveForegroundStyle(rowType.iconColor.toColor)
//            }
//            if reusedItems.count > 5 {
//                reuseText()
//                HStack {
//                    CapsuleTextButton(title: #localized("See all"),
//                                      titleColor: rowType.iconColor,
//                                      backgroundColor: rowType.iconColor.withAlphaComponent(0.2),
//                                      action: { viewModel.showItemList() })
//                        .fixedSize(horizontal: true, vertical: true)
//                    Spacer()
//                }
//                .frame(maxWidth: .infinity, alignment: .leading)
//            } else {
//                VStack(alignment: .leading) {
//                    reuseText()
//                    ReusedItemsPassListView(reusedPasswordItems: reusedItems,
//                                            action: { viewModel.showDetail(for: $0) })
//                }
//            }
//        }
//    }
// }
//
// struct ReusedItemsPassListView: View {
//    let reusedPasswordItems: [ItemContent]
//    let action: (ItemContent) -> Void
//
//    var body: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(alignment: .center, spacing: 8) {
//                ForEach(reusedPasswordItems) { item in
//                    Button {
//                        action(item)
//                    } label: {
//                        HStack(alignment: .center, spacing: 8) {
//                            ItemSquircleThumbnail(data: item.thumbnailData(),
//                                                  size: .small,
//                                                  alternativeBackground: true)
//                            Text(item.title)
//                                .lineLimit(1)
//                                .foregroundStyle(PassColor.textNorm.toColor)
//                                .padding(.trailing, 8)
//                        }
//                        .padding(8)
//                        .frame(maxWidth: 165, alignment: .leading)
//                        .background(item.type.normMinor1Color.toColor)
//                        .cornerRadius(16)
//                    }
//                }
//            }
//        }
//    }
// }
