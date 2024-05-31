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
                        row(title: IdentityFields.firstName.title, value: viewModel.firstName) {
                            viewModel.copyValueToClipboard(value: viewModel.firstName,
                                                           message: IdentityFields.firstName.title)
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.middleName.isEmpty {
                        row(title: IdentityFields.middleName.title, value: viewModel.middleName) {
                            viewModel.copyValueToClipboard(value: viewModel.middleName,
                                                           message: IdentityFields.middleName.title)
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.lastName.isEmpty {
                        row(title: IdentityFields.lastName.title, value: viewModel.lastName) {
                            viewModel.copyValueToClipboard(value: viewModel.lastName,
                                                           message: IdentityFields.lastName.title)
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.fullName.isEmpty {
                        row(title: IdentityFields.fullName.title, value: viewModel.fullName) {
                            viewModel.copyValueToClipboard(value: viewModel.fullName,
                                                           message: IdentityFields.fullName.title)
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.email.isEmpty {
                        row(title: IdentityFields.email.title, value: viewModel.email) {
                            viewModel.copyValueToClipboard(value: viewModel.email,
                                                           message: IdentityFields.email.title)
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.phoneNumber.isEmpty {
                        row(title: IdentityFields.phoneNumber.title, value: viewModel.phoneNumber) {
                            viewModel.copyValueToClipboard(value: viewModel.phoneNumber,
                                                           message: IdentityFields.phoneNumber.title)
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.birthdate.isEmpty {
                        row(title: IdentityFields.birthdate.title, value: viewModel.birthdate) {
                            viewModel.copyValueToClipboard(value: viewModel.birthdate,
                                                           message: IdentityFields.birthdate.title)
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.gender.isEmpty {
                        row(title: IdentityFields.gender.title, value: viewModel.gender) {
                            viewModel.copyValueToClipboard(value: viewModel.gender,
                                                           message: IdentityFields.gender.title)
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
                        row(title: IdentityFields.organization.title, value: viewModel.organization) {
                            viewModel.copyValueToClipboard(value: viewModel.organization,
                                                           message: IdentityFields.organization.title)
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.streetAddress.isEmpty {
                        row(title: IdentityFields.streetAddress.title, value: viewModel.streetAddress) {
                            viewModel.copyValueToClipboard(value: viewModel.streetAddress,
                                                           message: IdentityFields.streetAddress.title)
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.zipOrPostalCode.isEmpty {
                        row(title: IdentityFields.zipOrPostalCode.title, value: viewModel.zipOrPostalCode) {
                            viewModel.copyValueToClipboard(value: viewModel.zipOrPostalCode,
                                                           message: IdentityFields.zipOrPostalCode.title)
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.city.isEmpty {
                        row(title: IdentityFields.city.title, value: viewModel.city) {
                            viewModel.copyValueToClipboard(value: viewModel.city,
                                                           message: IdentityFields.city.title)
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.stateOrProvince.isEmpty {
                        row(title: IdentityFields.stateOrProvince.title, value: viewModel.stateOrProvince) {
                            viewModel.copyValueToClipboard(value: viewModel.stateOrProvince,
                                                           message: IdentityFields.stateOrProvince.title)
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.countryOrRegion.isEmpty {
                        row(title: IdentityFields.countryOrRegion.title, value: viewModel.countryOrRegion) {
                            viewModel.copyValueToClipboard(value: viewModel.countryOrRegion,
                                                           message: IdentityFields.countryOrRegion.title)
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.floor.isEmpty {
                        row(title: IdentityFields.floor.title, value: viewModel.floor) {
                            viewModel.copyValueToClipboard(value: viewModel.floor,
                                                           message: IdentityFields.floor.title)
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.county.isEmpty {
                        row(title: IdentityFields.county.title, value: viewModel.county) {
                            viewModel.copyValueToClipboard(value: viewModel.county,
                                                           message: IdentityFields.county.title)
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
                        row(title: IdentityFields.socialSecurityNumber.title,
                            value: viewModel.socialSecurityNumber) {
                                viewModel.copyValueToClipboard(value: viewModel.socialSecurityNumber,
                                                               message: IdentityFields.socialSecurityNumber.title)
                            }

                        PassSectionDivider()
                    }

                    if !viewModel.passportNumber.isEmpty {
                        row(title: IdentityFields.passportNumber.title, value: viewModel.passportNumber) {
                            viewModel.copyValueToClipboard(value: viewModel.passportNumber,
                                                           message: IdentityFields.passportNumber.title)
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.licenseNumber.isEmpty {
                        row(title: IdentityFields.licenseNumber.title, value: viewModel.licenseNumber) {
                            viewModel.copyValueToClipboard(value: viewModel.licenseNumber,
                                                           message: IdentityFields.licenseNumber.title)
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.website.isEmpty {
                        row(title: IdentityFields.website.title, value: viewModel.website) {
                            viewModel.copyValueToClipboard(value: viewModel.website,
                                                           message: IdentityFields.website.title)
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.xHandle.isEmpty {
                        row(title: IdentityFields.xHandle.title, value: viewModel.xHandle) {
                            viewModel.copyValueToClipboard(value: viewModel.xHandle,
                                                           message: IdentityFields.xHandle.title)
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.secondPhoneNumber.isEmpty {
                        row(title: IdentityFields.secondPhoneNumber.title, value: viewModel.secondPhoneNumber) {
                            viewModel.copyValueToClipboard(value: viewModel.secondPhoneNumber,
                                                           message: IdentityFields.secondPhoneNumber.title)
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.linkedIn.isEmpty {
                        row(title: IdentityFields.linkedIn.title, value: viewModel.linkedIn) {
                            viewModel.copyValueToClipboard(value: viewModel.linkedIn,
                                                           message: IdentityFields.linkedIn.title)
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.reddit.isEmpty {
                        row(title: IdentityFields.reddit.title, value: viewModel.reddit) {
                            viewModel.copyValueToClipboard(value: viewModel.reddit,
                                                           message: IdentityFields.reddit.title)
                        }
                        PassSectionDivider()
                    }

                    if !viewModel.facebook.isEmpty {
                        row(title: IdentityFields.facebook.title, value: viewModel.facebook) {
                            viewModel.copyValueToClipboard(value: viewModel.facebook,
                                                           message: IdentityFields.facebook.title)
                        }
                        PassSectionDivider()
                    }

                    if !viewModel.yahoo.isEmpty {
                        row(title: IdentityFields.yahoo.title, value: viewModel.yahoo) {
                            viewModel.copyValueToClipboard(value: viewModel.yahoo,
                                                           message: IdentityFields.yahoo.title)
                        }
                        PassSectionDivider()
                    }

                    if !viewModel.instagram.isEmpty {
                        row(title: IdentityFields.instagram.title, value: viewModel.instagram) {
                            viewModel.copyValueToClipboard(value: viewModel.instagram,
                                                           message: IdentityFields.instagram.title)
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
                        row(title: IdentityFields.company.title, value: viewModel.company) {
                            viewModel.copyValueToClipboard(value: viewModel.company,
                                                           message: IdentityFields.company.title)
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.jobTitle.isEmpty {
                        row(title: IdentityFields.jobTitle.title, value: viewModel.jobTitle) {
                            viewModel.copyValueToClipboard(value: viewModel.jobTitle,
                                                           message: IdentityFields.jobTitle.title)
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.personalWebsite.isEmpty {
                        row(title: IdentityFields.personalWebsite.title, value: viewModel.personalWebsite) {
                            viewModel.copyValueToClipboard(value: viewModel.personalWebsite,
                                                           message: IdentityFields.personalWebsite.title)
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.workPhoneNumber.isEmpty {
                        row(title: IdentityFields.workPhoneNumber.title, value: viewModel.workPhoneNumber) {
                            viewModel.copyValueToClipboard(value: viewModel.workPhoneNumber,
                                                           message: IdentityFields.workPhoneNumber.title)
                        }

                        PassSectionDivider()
                    }

                    if !viewModel.workEmail.isEmpty {
                        row(title: IdentityFields.workEmail.title, value: viewModel.workEmail) {
                            viewModel.copyValueToClipboard(value: viewModel.workEmail,
                                                           message: IdentityFields.workEmail.title)
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
        }
    }
}
