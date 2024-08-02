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

                    if viewModel.showWorkSection {
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
        .animation(.default, value: viewModel.moreInfoSectionExpanded)
        .itemDetailSetUp(viewModel)
    }
}

private extension IdentityDetailView {
    var personalDetailSection: some View {
        Section {
            VStack(alignment: .leading) {
                VStack(spacing: DesignConstant.sectionPadding) {
                    rowWithDivider(title: IdentityFields.firstName.title,
                                   value: viewModel.firstName,
                                   fields: viewModel.nonEmptyPersonalElement)

                    rowWithDivider(title: IdentityFields.middleName.title,
                                   value: viewModel.middleName,
                                   fields: viewModel.nonEmptyPersonalElement)

                    rowWithDivider(title: IdentityFields.lastName.title,
                                   value: viewModel.lastName,
                                   fields: viewModel.nonEmptyPersonalElement)

                    rowWithDivider(title: IdentityFields.fullName.title,
                                   value: viewModel.fullName,
                                   fields: viewModel.nonEmptyPersonalElement)

                    rowWithDivider(title: IdentityFields.email.title,
                                   value: viewModel.email,
                                   fields: viewModel.nonEmptyPersonalElement)

                    rowWithDivider(title: IdentityFields.phoneNumber.title,
                                   value: viewModel.phoneNumber,
                                   fields: viewModel.nonEmptyPersonalElement)

                    rowWithDivider(title: IdentityFields.birthdate.title,
                                   value: viewModel.birthdate,
                                   fields: viewModel.nonEmptyPersonalElement)

                    if !viewModel.gender.isEmpty {
                        row(title: IdentityFields.gender.title, value: viewModel.gender) {
                            viewModel.copyValueToClipboard(value: viewModel.gender,
                                                           message: IdentityFields.gender.title)
                        }
                    }

                    if !viewModel.extraPersonalDetails.isEmpty, !viewModel.nonEmptyPersonalElement.isEmpty {
                        PassSectionDivider()
                    }

                    CustomFieldSections(itemContentType: viewModel.itemContent.type,
                                        uiModels: viewModel.extraPersonalDetails,
                                        isFreeUser: viewModel.isFreeUser,
                                        isASection: false,
                                        showIcon: false,
                                        onSelectHiddenText: { viewModel.copyHiddenText($0) },
                                        onSelectTotpToken: { viewModel.copyTotpToken($0) },
                                        onUpgrade: { viewModel.upgrade() })
                }
                .padding(.vertical, DesignConstant.sectionPadding)
                .roundedDetailSection()
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
                    rowWithDivider(title: IdentityFields.organization.title,
                                   value: viewModel.organization,
                                   fields: viewModel.nonEmptyAddressElement)

                    rowWithDivider(title: IdentityFields.streetAddress.title,
                                   value: viewModel.streetAddress,
                                   fields: viewModel.nonEmptyAddressElement)

                    rowWithDivider(title: IdentityFields.zipOrPostalCode.title,
                                   value: viewModel.zipOrPostalCode,
                                   fields: viewModel.nonEmptyAddressElement)

                    rowWithDivider(title: IdentityFields.city.title,
                                   value: viewModel.city,
                                   fields: viewModel.nonEmptyAddressElement)

                    rowWithDivider(title: IdentityFields.stateOrProvince.title,
                                   value: viewModel.stateOrProvince,
                                   fields: viewModel.nonEmptyAddressElement)

                    rowWithDivider(title: IdentityFields.countryOrRegion.title,
                                   value: viewModel.countryOrRegion,
                                   fields: viewModel.nonEmptyAddressElement)

                    rowWithDivider(title: IdentityFields.floor.title,
                                   value: viewModel.floor,
                                   fields: viewModel.nonEmptyAddressElement)

                    if !viewModel.county.isEmpty {
                        PassSectionDivider()
                        row(title: IdentityFields.county.title, value: viewModel.county) {
                            viewModel.copyValueToClipboard(value: viewModel.county,
                                                           message: IdentityFields.county.title)
                        }
                    }

                    if !viewModel.extraAddressDetails.isEmpty, !viewModel.nonEmptyAddressElement.isEmpty {
                        PassSectionDivider()
                    }

                    CustomFieldSections(itemContentType: viewModel.itemContent.type,
                                        uiModels: viewModel.extraAddressDetails,
                                        isFreeUser: viewModel.isFreeUser,
                                        isASection: false,
                                        showIcon: false,
                                        onSelectHiddenText: { viewModel.copyHiddenText($0) },
                                        onSelectTotpToken: { viewModel.copyTotpToken($0) },
                                        onUpgrade: { viewModel.upgrade() })
                }
                .padding(.vertical, DesignConstant.sectionPadding)
                .roundedDetailSection()
            }
        } header: {
            sectionHeader(title: "Address details")
        }
    }
}

private extension IdentityDetailView {
    var contactDetailSection: some View {
        Section {
            VStack(alignment: .leading) {
                VStack(spacing: DesignConstant.sectionPadding) {
                    rowWithDivider(title: IdentityFields.socialSecurityNumber.title,
                                   value: viewModel.socialSecurityNumber,
                                   fields: viewModel.nonEmptyContactElement)

                    rowWithDivider(title: IdentityFields.passportNumber.title,
                                   value: viewModel.passportNumber,
                                   fields: viewModel.nonEmptyContactElement)

                    rowWithDivider(title: IdentityFields.licenseNumber.title,
                                   value: viewModel.licenseNumber,
                                   fields: viewModel.nonEmptyContactElement)

                    rowWithDivider(title: IdentityFields.website.title,
                                   value: viewModel.website,
                                   fields: viewModel.nonEmptyContactElement)

                    rowWithDivider(title: IdentityFields.xHandle.title,
                                   value: viewModel.xHandle,
                                   fields: viewModel.nonEmptyContactElement)

                    rowWithDivider(title: IdentityFields.secondPhoneNumber.title,
                                   value: viewModel.secondPhoneNumber,
                                   fields: viewModel.nonEmptyContactElement)

                    rowWithDivider(title: IdentityFields.linkedIn.title,
                                   value: viewModel.linkedIn,
                                   fields: viewModel.nonEmptyContactElement)

                    rowWithDivider(title: IdentityFields.reddit.title,
                                   value: viewModel.reddit,
                                   fields: viewModel.nonEmptyContactElement)

                    rowWithDivider(title: IdentityFields.facebook.title,
                                   value: viewModel.facebook,
                                   fields: viewModel.nonEmptyContactElement)

                    rowWithDivider(title: IdentityFields.yahoo.title,
                                   value: viewModel.yahoo,
                                   fields: viewModel.nonEmptyContactElement)

                    if !viewModel.instagram.isEmpty {
                        row(title: IdentityFields.instagram.title, value: viewModel.instagram) {
                            viewModel.copyValueToClipboard(value: viewModel.instagram,
                                                           message: IdentityFields.instagram.title)
                        }
                    }

                    if !viewModel.extraContactDetails.isEmpty, !viewModel.nonEmptyContactElement.isEmpty {
                        PassSectionDivider()
                    }

                    CustomFieldSections(itemContentType: viewModel.itemContent.type,
                                        uiModels: viewModel.extraContactDetails,
                                        isFreeUser: viewModel.isFreeUser,
                                        isASection: false,
                                        showIcon: false,
                                        onSelectHiddenText: { viewModel.copyHiddenText($0) },
                                        onSelectTotpToken: { viewModel.copyTotpToken($0) },
                                        onUpgrade: { viewModel.upgrade() })
                }
                .padding(.vertical, DesignConstant.sectionPadding)
                .roundedDetailSection()
            }
        } header: {
            sectionHeader(title: "Contact details")
        }
    }
}

private extension IdentityDetailView {
    var workDetailSection: some View {
        Section {
            VStack(alignment: .leading) {
                VStack(spacing: DesignConstant.sectionPadding) {
                    rowWithDivider(title: IdentityFields.company.title,
                                   value: viewModel.company,
                                   fields: viewModel.nonEmptyWorkElement)

                    rowWithDivider(title: IdentityFields.jobTitle.title,
                                   value: viewModel.jobTitle,
                                   fields: viewModel.nonEmptyWorkElement)

                    rowWithDivider(title: IdentityFields.personalWebsite.title,
                                   value: viewModel.personalWebsite,
                                   fields: viewModel.nonEmptyWorkElement)

                    rowWithDivider(title: IdentityFields.workPhoneNumber.title,
                                   value: viewModel.workPhoneNumber,
                                   fields: viewModel.nonEmptyWorkElement)

                    if !viewModel.workEmail.isEmpty {
                        row(title: IdentityFields.workEmail.title, value: viewModel.workEmail) {
                            viewModel.copyValueToClipboard(value: viewModel.workEmail,
                                                           message: IdentityFields.workEmail.title)
                        }
                    }

                    if !viewModel.extraWorkDetails.isEmpty, !viewModel.nonEmptyWorkElement.isEmpty {
                        PassSectionDivider()
                    }

                    CustomFieldSections(itemContentType: viewModel.itemContent.type,
                                        uiModels: viewModel.extraWorkDetails,
                                        isFreeUser: viewModel.isFreeUser,
                                        isASection: false,
                                        showIcon: false,
                                        onSelectHiddenText: { viewModel.copyHiddenText($0) },
                                        onSelectTotpToken: { viewModel.copyTotpToken($0) },
                                        onUpgrade: { viewModel.upgrade() })
                }
                .padding(.vertical, DesignConstant.sectionPadding)
                .roundedDetailSection()
            }
        } header: {
            sectionHeader(title: "Work details")
        }
    }
}

private extension IdentityDetailView {
    func customDetailSection(customSection: CustomSection) -> some View {
        Section {
            if customSection.content.isEmpty {
                Text("Empty section")
                    .font(.callout.italic())
                    .adaptiveForegroundStyle(PassColor.textWeak.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                CustomFieldSections(itemContentType: viewModel.itemContent.type,
                                    uiModels: customSection.content
                                        .map(\.toCustomFieldUiModel),
                                    isFreeUser: viewModel.isFreeUser,
                                    showIcon: false,
                                    onSelectHiddenText: { viewModel.copyHiddenText($0) },
                                    onSelectTotpToken: { viewModel.copyTotpToken($0) },
                                    onUpgrade: { viewModel.upgrade() })
            }
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

    @ViewBuilder
    func rowWithDivider(title: String, value: String, fields: [String]) -> some View {
        if !value.isEmpty {
            row(title: title, value: value) {
                viewModel.copyValueToClipboard(value: value,
                                               message: title)
            }

            if !fields.isLastNonEmptyElement(value,
                                             isEmpty: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                             }) {
                PassSectionDivider()
            }
        }
    }

    func sectionHeader(title: LocalizedStringKey) -> some View {
        Text(title)
            .foregroundStyle(PassColor.textWeak.toColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, DesignConstant.sectionPadding)
            .padding(.vertical, DesignConstant.sectionPadding)
    }
}
