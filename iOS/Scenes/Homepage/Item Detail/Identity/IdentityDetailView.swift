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
                            .padding(.bottom, 25)

                        if viewModel.showPersonalSection {
                            personalDetailSection
                        }

                        if viewModel.showAddressSection {
                            addressDetailSection
                        }

                        if viewModel.showContactSection {
                            contactDetailSection
                        }

                        if viewModel.showWordSection {
                            workDetailSection
                        }

                        ForEach(viewModel.extraSections) { customSection in
                            customDetailSection(customSection: customSection)
                        }

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
        .toolbarBackground(PassColor.backgroundNorm.toColor,
                           for: .navigationBar)
    }
}

private extension IdentityDetailView {
    var personalDetailSection: some View {
        Section {
            VStack(alignment: .leading) {
                VStack(spacing: DesignConstant.sectionPadding) {
                    if !viewModel.firstName.isEmpty {
                        row(title: #localized("First name"), value: viewModel.firstName) {
                            viewModel.copyValueToClipboard(value: viewModel.firstName,
                                                           message: #localized("First name"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.middleName.isEmpty {
                        row(title: #localized("Middle name"), value: viewModel.middleName) {
                            viewModel.copyValueToClipboard(value: viewModel.middleName,
                                                           message: #localized("Middle name"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.lastName.isEmpty {
                        row(title: #localized("Last name"), value: viewModel.lastName) {
                            viewModel.copyValueToClipboard(value: viewModel.lastName,
                                                           message: #localized("Last name"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.fullName.isEmpty {
                        row(title: #localized("Full name"), value: viewModel.fullName) {
                            viewModel.copyValueToClipboard(value: viewModel.fullName,
                                                           message: #localized("Full name"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.email.isEmpty {
                        row(title: #localized("Email"), value: viewModel.email) {
                            viewModel.copyValueToClipboard(value: viewModel.email,
                                                           message: #localized("Email"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.phoneNumber.isEmpty {
                        row(title: #localized("Phone number"), value: viewModel.phoneNumber) {
                            viewModel.copyValueToClipboard(value: viewModel.phoneNumber,
                                                           message: #localized("Phone number"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.birthdate.isEmpty {
                        row(title: #localized("Birthdate"), value: viewModel.birthdate) {
                            viewModel.copyValueToClipboard(value: viewModel.birthdate,
                                                           message: #localized("Birthdate"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.gender.isEmpty {
                        row(title: #localized("Gender"), value: viewModel.gender) {
                            viewModel.copyValueToClipboard(value: viewModel.gender,
                                                           message: #localized("Gender"))
                        }

                        PassSectionDivider()
                    }

                    CustomFieldSections(itemContentType: viewModel.itemContent.type,
                                        uiModels: viewModel.extraPersonalDetails,
                                        isFreeUser: viewModel.isFreeUser,
                                        isASection: false,
                                        showIcon: false,
                                        onSelectText: {
                                            viewModel.copyValueToClipboard(value: $0,
                                                                           message: #localized("Custom field"))
                                        },
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
                .padding(.vertical, DesignConstant.sectionPadding)
        }
    }
}

private extension IdentityDetailView {
    var addressDetailSection: some View {
        Section {
            VStack(alignment: .leading) {
                VStack(spacing: DesignConstant.sectionPadding) {
                    if !viewModel.organization.isEmpty {
                        row(title: #localized("Organization"), value: viewModel.organization) {
                            viewModel.copyValueToClipboard(value: viewModel.organization,
                                                           message: #localized("Organization"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.streetAddress.isEmpty {
                        row(title: #localized("Street address, P.O. box"), value: viewModel.streetAddress) {
                            viewModel.copyValueToClipboard(value: viewModel.streetAddress,
                                                           message: #localized("Street address, P.O. box"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.zipOrPostalCode.isEmpty {
                        row(title: #localized("ZIP or Postal code"), value: viewModel.zipOrPostalCode) {
                            viewModel.copyValueToClipboard(value: viewModel.zipOrPostalCode,
                                                           message: #localized("ZIP or Postal code"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.city.isEmpty {
                        row(title: "City", value: viewModel.city) {
                            viewModel.copyValueToClipboard(value: viewModel.city,
                                                           message: #localized("City"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.stateOrProvince.isEmpty {
                        row(title: "State or province", value: viewModel.stateOrProvince) {
                            viewModel.copyValueToClipboard(value: viewModel.stateOrProvince,
                                                           message: #localized("State or province"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.countryOrRegion.isEmpty {
                        row(title: "Country or Region", value: viewModel.countryOrRegion) {
                            viewModel.copyValueToClipboard(value: viewModel.countryOrRegion,
                                                           message: #localized("Country or Region"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.floor.isEmpty {
                        row(title: "Floor", value: viewModel.floor) {
                            viewModel.copyValueToClipboard(value: viewModel.floor,
                                                           message: #localized("Floor"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.county.isEmpty {
                        row(title: "County", value: viewModel.county) {
                            viewModel.copyValueToClipboard(value: viewModel.county,
                                                           message: #localized("County"))
                        }
                        PassSectionDivider()
                    }

                    CustomFieldSections(itemContentType: viewModel.itemContent.type,
                                        uiModels: viewModel.extraAddressDetails,
                                        isFreeUser: viewModel.isFreeUser,
                                        isASection: false,
                                        showIcon: false,
                                        onSelectText: {
                                            viewModel.copyValueToClipboard(value: $0,
                                                                           message: #localized("Custom field"))
                                        },
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
                .padding(.vertical, DesignConstant.sectionPadding)
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
                                                           message: #localized("Social security number"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.passportNumber.isEmpty {
                        row(title: "Passport number", value: viewModel.passportNumber) {
                            viewModel.copyValueToClipboard(value: viewModel.passportNumber,
                                                           message: #localized("Passport number"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.licenseNumber.isEmpty {
                        row(title: "License number", value: viewModel.licenseNumber) {
                            viewModel.copyValueToClipboard(value: viewModel.licenseNumber,
                                                           message: #localized("License number"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.website.isEmpty {
                        row(title: "Website", value: viewModel.website) {
                            viewModel.copyValueToClipboard(value: viewModel.website,
                                                           message: #localized("Website"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.xHandle.isEmpty {
                        row(title: "X handle", value: viewModel.xHandle) {
                            viewModel.copyValueToClipboard(value: viewModel.xHandle,
                                                           message: #localized("X handle"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.secondPhoneNumber.isEmpty {
                        row(title: "Second phone number", value: viewModel.secondPhoneNumber) {
                            viewModel.copyValueToClipboard(value: viewModel.secondPhoneNumber,
                                                           message: #localized("Second phone number"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.linkedin.isEmpty {
                        row(title: "Linkedin", value: viewModel.linkedin) {
                            viewModel.copyValueToClipboard(value: viewModel.linkedin,
                                                           message: #localized("Linkedin"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.reddit.isEmpty {
                        row(title: "Reddit", value: viewModel.reddit) {
                            viewModel.copyValueToClipboard(value: viewModel.reddit,
                                                           message: #localized("Reddit"))
                        }
                        PassSectionDivider()
                    }

                    if !viewModel.facebook.isEmpty {
                        row(title: "Facebook", value: viewModel.facebook) {
                            viewModel.copyValueToClipboard(value: viewModel.facebook,
                                                           message: #localized("Facebook"))
                        }
                        PassSectionDivider()
                    }

                    if !viewModel.yahoo.isEmpty {
                        row(title: "Yahoo", value: viewModel.yahoo) {
                            viewModel.copyValueToClipboard(value: viewModel.yahoo,
                                                           message: #localized("Yahoo"))
                        }
                        PassSectionDivider()
                    }

                    if !viewModel.instagram.isEmpty {
                        row(title: "Instagram", value: viewModel.instagram) {
                            viewModel.copyValueToClipboard(value: viewModel.instagram,
                                                           message: #localized("Instagram"))
                        }
                        PassSectionDivider()
                    }

                    CustomFieldSections(itemContentType: viewModel.itemContent.type,
                                        uiModels: viewModel.extraContactDetails,
                                        isFreeUser: viewModel.isFreeUser,
                                        isASection: false,
                                        showIcon: false,
                                        onSelectText: {
                                            viewModel.copyValueToClipboard(value: $0,
                                                                           message: #localized("Custom field"))
                                        },
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
                .padding(.vertical, DesignConstant.sectionPadding)
        }
    }
}

private extension IdentityDetailView {
    var workDetailSection: some View {
        Section {
            VStack(alignment: .leading) {
                VStack(spacing: DesignConstant.sectionPadding) {
                    if !viewModel.company.isEmpty {
                        row(title: "Company", value: viewModel.company) {
                            viewModel.copyValueToClipboard(value: viewModel.company,
                                                           message: #localized("Company"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.jobTitle.isEmpty {
                        row(title: "Job title", value: viewModel.jobTitle) {
                            viewModel.copyValueToClipboard(value: viewModel.jobTitle,
                                                           message: #localized("Job title"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.personalWebsite.isEmpty {
                        row(title: "Personal website", value: viewModel.personalWebsite) {
                            viewModel.copyValueToClipboard(value: viewModel.personalWebsite,
                                                           message: #localized("Personal website"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.workPhoneNumber.isEmpty {
                        row(title: "Work phone number", value: viewModel.workPhoneNumber) {
                            viewModel.copyValueToClipboard(value: viewModel.workPhoneNumber,
                                                           message: #localized("Work phone number"))
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.workEmail.isEmpty {
                        row(title: "Work email", value: viewModel.workEmail) {
                            viewModel.copyValueToClipboard(value: viewModel.workEmail,
                                                           message: #localized("Work email"))
                        }

                        PassSectionDivider()
                    }

                    CustomFieldSections(itemContentType: viewModel.itemContent.type,
                                        uiModels: viewModel.extraWorkDetails,
                                        isFreeUser: viewModel.isFreeUser,
                                        isASection: false,
                                        showIcon: false,
                                        onSelectText: {
                                            viewModel.copyValueToClipboard(value: $0,
                                                                           message: #localized("Custom field"))
                                        },
                                        onSelectHiddenText: { viewModel.copyHiddenText($0) },
                                        onSelectTotpToken: { viewModel.copyTotpToken($0) },
                                        onUpgrade: { viewModel.upgrade() })
                }
                .padding(.vertical, DesignConstant.sectionPadding)
                .roundedEditableSection()
            }
        } header: {
            Text("Work details")
                .foregroundStyle(PassColor.textWeak.toColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, DesignConstant.sectionPadding)
                .padding(.vertical, DesignConstant.sectionPadding)
        }
    }
}

private extension IdentityDetailView {
    func customDetailSection(customSection: CustomSection) -> some View {
        Section {
            CustomFieldSections(itemContentType: viewModel.itemContent.type,
                                uiModels: customSection.content
                                    .map(\.toCustomFieldUiModel),
                                isFreeUser: viewModel.isFreeUser,
                                showIcon: false,
                                onSelectText: { viewModel.copyValueToClipboard(value: $0,
                                                                               message: #localized("Custom field"))
                                },
                                onSelectHiddenText: { viewModel.copyHiddenText($0) },
                                onSelectTotpToken: { viewModel.copyTotpToken($0) },
                                onUpgrade: { viewModel.upgrade() })
        } header: {
            Text(customSection.title)
                .foregroundStyle(PassColor.textWeak.toColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, DesignConstant.sectionPadding)
                .padding(.vertical, DesignConstant.sectionPadding)
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
