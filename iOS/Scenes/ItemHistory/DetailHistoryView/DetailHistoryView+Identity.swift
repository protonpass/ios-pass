//
// DetailHistoryView+Identity.swift
// Proton Pass - Created on 29/05/2024.
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

import DesignSystem
import Entities
import Factory
import Macro
import ProtonCoreUIFoundations
import SwiftUI

extension DetailHistoryView {
    var identityView: some View {
        VStack(alignment: .leading, spacing: 0) {
            let itemContent = viewModel.selectedRevisionContent

            titleRow(itemContent: itemContent)

            if let item = itemContent.identityItem {
                personalDetailSection(item: item)
                addressDetailSection(item: item)
                contactDetailSection(item: item)
                workDetailSection(item: item)
                ForEach(Array(item.extraSections.enumerated()), id: \.element.id) { (index, customSection) in
                    customDetailSection(customSection: customSection, index: index)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private extension DetailHistoryView {
    func personalDetailSection(item: IdentityData) -> some View {
        Section {
            VStack(alignment: .leading) {
                VStack(spacing: DesignConstant.sectionPadding) {
                    row(title: IdentityFields.firstName.localisedKeyTitle,
                        value: item.firstName,
                        element: \.identityItem?.firstName) {
                            viewModel.copyValueToClipboard(value: item.firstName,
                                                           message: IdentityFields.firstName.title)
                        }

                    PassSectionDivider()

                    row(title: IdentityFields.middleName.localisedKeyTitle,
                        value: item.middleName,
                        element: \.identityItem?.middleName) {
                            viewModel.copyValueToClipboard(value: item.middleName,
                                                           message: IdentityFields.middleName.title)
                        }

                    PassSectionDivider()

                    row(title: IdentityFields.lastName.localisedKeyTitle,
                        value: item.lastName,
                        element: \.identityItem?.lastName) {
                            viewModel.copyValueToClipboard(value: item.lastName,
                                                           message: IdentityFields.lastName.title)
                        }
                    PassSectionDivider()

                    row(title: IdentityFields.fullName.localisedKeyTitle,
                        value: item.fullName,
                        element: \.identityItem?.lastName) {
                            viewModel.copyValueToClipboard(value: item.fullName,
                                                           message:  IdentityFields.fullName.title)
                        }

                    PassSectionDivider()

                    row(title: IdentityFields.email.localisedKeyTitle,
                        value: item.email,
                        element: \.identityItem?.email) {
                            viewModel.copyValueToClipboard(value: item.email,
                                                           message: IdentityFields.email.title)
                        }

                    PassSectionDivider()

                    row(title: IdentityFields.phoneNumber.localisedKeyTitle,
                        value: item.phoneNumber,
                        element: \.identityItem?.phoneNumber) {
                            viewModel.copyValueToClipboard(value: item.phoneNumber,
                                                           message: IdentityFields.phoneNumber.title)
                        }

                    PassSectionDivider()

                    row(title: IdentityFields.birthdate.localisedKeyTitle,
                        value: item.birthdate,
                        element: \.identityItem?.birthdate) {
                            viewModel.copyValueToClipboard(value: item.birthdate,
                                                           message: IdentityFields.birthdate.title)
                        }

                    PassSectionDivider()

                    row(title: IdentityFields.gender.localisedKeyTitle,
                        value: item.gender,
                        element: \.identityItem?.gender) {
                            viewModel.copyValueToClipboard(value: item.gender,
                                                           message: IdentityFields.gender.title)
                        }
                }
                .padding(.vertical, DesignConstant.sectionPadding)
                .roundedEditableSection()
                customFields(uiModels: item.extraPersonalDetails.map(\.toCustomFieldUiModel),
                             element: \.identityItem?.extraPersonalDetails)
            }
        } header: {
            Text("Personal details")
                .foregroundStyle(PassColor.textWeak.toColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, DesignConstant.sectionPadding)
        }
    }
}

private extension DetailHistoryView {
    func addressDetailSection(item: IdentityData) -> some View {
        Section {
            VStack(alignment: .leading) {
                VStack(spacing: DesignConstant.sectionPadding) {
                    row(title: IdentityFields.organization.localisedKeyTitle,
                        value: item.organization,
                        element: \.identityItem?.organization) {
                            viewModel.copyValueToClipboard(value: item.organization,
                                                           message: IdentityFields.organization.title)
                        }

                    PassSectionDivider()

                    row(title: IdentityFields.streetAddress.localisedKeyTitle,
                        value: item.streetAddress,
                        element: \.identityItem?.streetAddress) {
                            viewModel.copyValueToClipboard(value: item.streetAddress,
                                                           message: IdentityFields.streetAddress.title)
                        }

                    PassSectionDivider()

                    row(title: IdentityFields.zipOrPostalCode.localisedKeyTitle,
                        value: item.zipOrPostalCode,
                        element: \.identityItem?.zipOrPostalCode) {
                            viewModel.copyValueToClipboard(value: item.zipOrPostalCode,
                                                           message: IdentityFields.zipOrPostalCode.title)
                        }

                    PassSectionDivider()

                    row(title: IdentityFields.city.localisedKeyTitle,
                        value: item.city,
                        element: \.identityItem?.city) {
                            viewModel.copyValueToClipboard(value: item.city,
                                                           message: IdentityFields.city.title)
                        }

                    PassSectionDivider()

                    row(title: IdentityFields.stateOrProvince.localisedKeyTitle,
                        value: item.stateOrProvince,
                        element: \.identityItem?.stateOrProvince) {
                            viewModel.copyValueToClipboard(value: item.stateOrProvince,
                                                           message: IdentityFields.stateOrProvince.title)
                        }

                    PassSectionDivider()

                    row(title: IdentityFields.countryOrRegion.localisedKeyTitle,
                        value: item.countryOrRegion,
                        element: \.identityItem?.countryOrRegion) {
                            viewModel.copyValueToClipboard(value: item.countryOrRegion,
                                                           message: IdentityFields.countryOrRegion.title)
                        }

                    PassSectionDivider()

                    row(title: IdentityFields.floor.localisedKeyTitle,
                        value: item.floor,
                        element: \.identityItem?.floor) {
                            viewModel.copyValueToClipboard(value: item.floor,
                                                           message: IdentityFields.floor.title)
                        }

                    PassSectionDivider()

                    row(title: IdentityFields.county.localisedKeyTitle,
                        value: item.county,
                        element: \.identityItem?.county) {
                            viewModel.copyValueToClipboard(value: item.county,
                                                           message: IdentityFields.county.title)
                        }
                }
                .padding(.vertical, DesignConstant.sectionPadding)
                .roundedEditableSection()
                customFields(uiModels: item.extraAddressDetails.map(\.toCustomFieldUiModel),
                             element: \.identityItem?.extraAddressDetails)
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

private extension DetailHistoryView {
    func contactDetailSection(item: IdentityData) -> some View {
        Section {
            VStack(alignment: .leading) {
                VStack(spacing: DesignConstant.sectionPadding) {
                    row(title: IdentityFields.socialSecurityNumber.localisedKeyTitle,
                        value: item.socialSecurityNumber,
                        element: \.identityItem?.socialSecurityNumber) {
                            viewModel.copyValueToClipboard(value: item.socialSecurityNumber,
                                                           message: IdentityFields.socialSecurityNumber.title)
                        }

                    PassSectionDivider()

                    row(title: IdentityFields.passportNumber.localisedKeyTitle,
                        value: item.passportNumber,
                        element: \.identityItem?.passportNumber) {
                            viewModel.copyValueToClipboard(value: item.passportNumber,
                                                           message: IdentityFields.passportNumber.title)
                        }

                    PassSectionDivider()

                    row(title: IdentityFields.licenseNumber.localisedKeyTitle,
                        value: item.licenseNumber,
                        element: \.identityItem?.licenseNumber) {
                            viewModel.copyValueToClipboard(value: item.licenseNumber,
                                                           message: IdentityFields.licenseNumber.title)
                        }

                    PassSectionDivider()

                    row(title: IdentityFields.website.localisedKeyTitle,
                        value: item.website,
                        element: \.identityItem?.website) {
                            viewModel.copyValueToClipboard(value: item.website,
                                                           message: IdentityFields.website.title)
                        }

                    PassSectionDivider()

                    row(title: IdentityFields.xHandle.localisedKeyTitle,
                        value: item.xHandle,
                        element: \.identityItem?.xHandle) {
                            viewModel.copyValueToClipboard(value: item.xHandle,
                                                           message: IdentityFields.xHandle.title)
                        }

                    PassSectionDivider()

                    row(title: IdentityFields.secondPhoneNumber.localisedKeyTitle,
                        value: item.secondPhoneNumber,
                        element: \.identityItem?.secondPhoneNumber) {
                            viewModel.copyValueToClipboard(value: item.secondPhoneNumber,
                                                           message: IdentityFields.secondPhoneNumber.title)
                        }

                    PassSectionDivider()

                    row(title: IdentityFields.linkedIn.localisedKeyTitle,
                        value: item.linkedIn,
                        element: \.identityItem?.linkedIn) {
                            viewModel.copyValueToClipboard(value: item.linkedIn,
                                                           message:  IdentityFields.linkedIn.title)
                        }

                    PassSectionDivider()

                    row(title: IdentityFields.reddit.localisedKeyTitle,
                        value: item.reddit,
                        element: \.identityItem?.reddit) {
                            viewModel.copyValueToClipboard(value: item.reddit,
                                                           message: IdentityFields.reddit.title)
                        }

                    PassSectionDivider()

                    row(title: IdentityFields.facebook.localisedKeyTitle,
                        value: item.facebook,
                        element: \.identityItem?.facebook) {
                            viewModel.copyValueToClipboard(value: item.facebook,
                                                           message: IdentityFields.facebook.title)
                        }

                    PassSectionDivider()

                    row(title:  IdentityFields.yahoo.localisedKeyTitle,
                        value: item.yahoo,
                        element: \.identityItem?.yahoo) {
                            viewModel.copyValueToClipboard(value: item.yahoo,
                                                           message: IdentityFields.yahoo.title)
                        }

                    PassSectionDivider()

                    row(title: IdentityFields.instagram.localisedKeyTitle,
                        value: item.instagram,
                        element: \.identityItem?.instagram) {
                            viewModel.copyValueToClipboard(value: item.instagram,
                                                           message: IdentityFields.instagram.title)
                        }
                }
                .padding(.vertical, DesignConstant.sectionPadding)
                .roundedEditableSection()
                customFields(uiModels: item.extraContactDetails.map(\.toCustomFieldUiModel),
                             element: \.identityItem?.extraContactDetails)
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

private extension DetailHistoryView {
    func workDetailSection(item: IdentityData) -> some View {
        Section {
            VStack(alignment: .leading) {
                VStack(spacing: DesignConstant.sectionPadding) {
                    row(title: IdentityFields.company.localisedKeyTitle,
                        value: item.company,
                        element: \.identityItem?.company) {
                            viewModel.copyValueToClipboard(value: item.company,
                                                           message: IdentityFields.company.title)
                        }

                    PassSectionDivider()

                    row(title: IdentityFields.jobTitle.localisedKeyTitle,
                        value: item.jobTitle,
                        element: \.identityItem?.jobTitle) {
                            viewModel.copyValueToClipboard(value: item.jobTitle,
                                                           message: IdentityFields.jobTitle.title)
                        }

                    PassSectionDivider()

                    row(title: IdentityFields.personalWebsite.localisedKeyTitle,
                        value: item.personalWebsite,
                        element: \.identityItem?.personalWebsite) {
                            viewModel.copyValueToClipboard(value: item.personalWebsite,
                                                           message: IdentityFields.personalWebsite.title)
                        }

                    PassSectionDivider()

                    row(title: IdentityFields.workPhoneNumber.localisedKeyTitle,
                        value: item.workPhoneNumber,
                        element: \.identityItem?.workPhoneNumber) {
                            viewModel.copyValueToClipboard(value: item.workPhoneNumber,
                                                           message: IdentityFields.workPhoneNumber.title)
                        }

                    PassSectionDivider()

                    row(title: IdentityFields.workEmail.localisedKeyTitle,
                        value: item.workEmail,
                        element: \.identityItem?.workEmail) {
                            viewModel.copyValueToClipboard(value: item.workEmail,
                                                           message: IdentityFields.workEmail.title)
                        }
                }
                .padding(.vertical, DesignConstant.sectionPadding)
                .roundedEditableSection()
                customFields(uiModels: item.extraWorkDetails.map(\.toCustomFieldUiModel),
                             element: \.identityItem?.extraWorkDetails)
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

private extension DetailHistoryView {
    func customDetailSection(customSection: CustomSection, index: Int) -> some View {
        Section {
            customFields(uiModels: customSection.content.map(\.toCustomFieldUiModel),
                         element: \.identityItem?.extraSections[index])
        } header: {
            Text(customSection.title)
                .foregroundStyle(PassColor.textWeak.toColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, DesignConstant.sectionPadding)
                .padding(.vertical, DesignConstant.sectionPadding)
        }
    }
}

private extension DetailHistoryView {
    func row(title: LocalizedStringKey, value: String, element: KeyPath<ItemContent, some Hashable>,
             onTap: @escaping () -> Void) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(title)
                    .sectionTitleText()

                Text(value)
                    .foregroundStyle(textColor(for: element).toColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture(perform: onTap)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }
    
    func customFields(uiModels: [CustomFieldUiModel], element: KeyPath<ItemContent, some Hashable>) -> some View {
        VStack(spacing: 0) {
            ForEach(uiModels) { uiModel in
                let customField = uiModel.customField
                let title = customField.title
                let content = customField.content

                HStack(spacing: DesignConstant.sectionPadding) {
                    VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                        Text(title)
                            .sectionTitleText()

                        Text(content)
                            .foregroundStyle(PassColor.textNorm.toColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(DesignConstant.sectionPadding)
                .roundedDetailSection()
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
        }
        .roundedDetailSection(borderColor: borderColor(for: element))
    }
}
