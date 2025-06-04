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
                customSections(item.extraSections)
            }

            customFields(item: itemContent)
                .padding(.top, 8)

            attachmentsSection(item: itemContent)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
    }
}

private extension DetailHistoryView {
    func personalDetailSection(item: IdentityData) -> some View {
        Section {
            VStack(alignment: .leading) {
                VStack(spacing: DesignConstant.sectionPadding) {
                    row(title: IdentityFields.firstName.title,
                        value: item.firstName,
                        element: \.identityItem?.firstName)

                    PassSectionDivider()

                    row(title: IdentityFields.middleName.title,
                        value: item.middleName,
                        element: \.identityItem?.middleName)

                    PassSectionDivider()

                    row(title: IdentityFields.lastName.title,
                        value: item.lastName,
                        element: \.identityItem?.lastName)

                    PassSectionDivider()

                    row(title: IdentityFields.fullName.title,
                        value: item.fullName,
                        element: \.identityItem?.fullName)

                    PassSectionDivider()

                    row(title: IdentityFields.email.title,
                        value: item.email,
                        element: \.identityItem?.email)

                    PassSectionDivider()

                    row(title: IdentityFields.phoneNumber.title,
                        value: item.phoneNumber,
                        element: \.identityItem?.phoneNumber)

                    PassSectionDivider()

                    row(title: IdentityFields.birthdate.title,
                        value: item.birthdate,
                        element: \.identityItem?.birthdate)

                    PassSectionDivider()

                    row(title: IdentityFields.gender.title,
                        value: item.gender,
                        element: \.identityItem?.gender)
                }
                .padding(.vertical, DesignConstant.sectionPadding)
                .roundedEditableSection()
                customFields(item.extraPersonalDetails,
                             border: borderColor(for: \.identityItem?.extraPersonalDetails))
            }
        } header: {
            sectionTitle(title: "Personal details")
        }
    }
}

private extension DetailHistoryView {
    func addressDetailSection(item: IdentityData) -> some View {
        Section {
            VStack(alignment: .leading) {
                VStack(spacing: DesignConstant.sectionPadding) {
                    row(title: IdentityFields.organization.title,
                        value: item.organization,
                        element: \.identityItem?.organization)

                    PassSectionDivider()

                    row(title: IdentityFields.streetAddress.title,
                        value: item.streetAddress,
                        element: \.identityItem?.streetAddress)

                    PassSectionDivider()

                    row(title: IdentityFields.zipOrPostalCode.title,
                        value: item.zipOrPostalCode,
                        element: \.identityItem?.zipOrPostalCode)

                    PassSectionDivider()

                    row(title: IdentityFields.city.title,
                        value: item.city,
                        element: \.identityItem?.city)

                    PassSectionDivider()

                    row(title: IdentityFields.stateOrProvince.title,
                        value: item.stateOrProvince,
                        element: \.identityItem?.stateOrProvince)

                    PassSectionDivider()

                    row(title: IdentityFields.countryOrRegion.title,
                        value: item.countryOrRegion,
                        element: \.identityItem?.countryOrRegion)

                    PassSectionDivider()

                    row(title: IdentityFields.floor.title,
                        value: item.floor,
                        element: \.identityItem?.floor)

                    PassSectionDivider()

                    row(title: IdentityFields.county.title,
                        value: item.county,
                        element: \.identityItem?.county)
                }
                .padding(.vertical, DesignConstant.sectionPadding)
                .roundedEditableSection()
                customFields(item.extraAddressDetails,
                             border: borderColor(for: \.identityItem?.extraAddressDetails))
            }
        } header: {
            sectionTitle(title: "Address details")
        }
    }
}

private extension DetailHistoryView {
    func contactDetailSection(item: IdentityData) -> some View {
        Section {
            VStack(alignment: .leading) {
                VStack(spacing: DesignConstant.sectionPadding) {
                    row(title: IdentityFields.socialSecurityNumber.title,
                        value: item.socialSecurityNumber,
                        element: \.identityItem?.socialSecurityNumber)

                    PassSectionDivider()

                    row(title: IdentityFields.passportNumber.title,
                        value: item.passportNumber,
                        element: \.identityItem?.passportNumber)

                    PassSectionDivider()

                    row(title: IdentityFields.licenseNumber.title,
                        value: item.licenseNumber,
                        element: \.identityItem?.licenseNumber)

                    PassSectionDivider()

                    row(title: IdentityFields.website.title,
                        value: item.website,
                        element: \.identityItem?.website)

                    PassSectionDivider()

                    row(title: IdentityFields.xHandle.title,
                        value: item.xHandle,
                        element: \.identityItem?.xHandle)

                    PassSectionDivider()

                    row(title: IdentityFields.secondPhoneNumber.title,
                        value: item.secondPhoneNumber,
                        element: \.identityItem?.secondPhoneNumber)

                    PassSectionDivider()

                    row(title: IdentityFields.linkedIn.title,
                        value: item.linkedIn,
                        element: \.identityItem?.linkedIn)

                    PassSectionDivider()

                    row(title: IdentityFields.reddit.title,
                        value: item.reddit,
                        element: \.identityItem?.reddit)

                    PassSectionDivider()

                    row(title: IdentityFields.facebook.title,
                        value: item.facebook,
                        element: \.identityItem?.facebook)

                    PassSectionDivider()

                    row(title: IdentityFields.yahoo.title,
                        value: item.yahoo,
                        element: \.identityItem?.yahoo)

                    PassSectionDivider()

                    row(title: IdentityFields.instagram.title,
                        value: item.instagram,
                        element: \.identityItem?.instagram)
                }
                .padding(.vertical, DesignConstant.sectionPadding)
                .roundedEditableSection()
                customFields(item.extraContactDetails,
                             border: borderColor(for: \.identityItem?.extraContactDetails))
            }
        } header: {
            sectionTitle(title: "Contact details")
        }
    }
}

private extension DetailHistoryView {
    func workDetailSection(item: IdentityData) -> some View {
        Section {
            VStack(alignment: .leading) {
                VStack(spacing: DesignConstant.sectionPadding) {
                    row(title: IdentityFields.company.title,
                        value: item.company,
                        element: \.identityItem?.company)

                    PassSectionDivider()

                    row(title: IdentityFields.jobTitle.title,
                        value: item.jobTitle,
                        element: \.identityItem?.jobTitle)

                    PassSectionDivider()

                    row(title: IdentityFields.personalWebsite.title,
                        value: item.personalWebsite,
                        element: \.identityItem?.personalWebsite)

                    PassSectionDivider()

                    row(title: IdentityFields.workPhoneNumber.title,
                        value: item.workPhoneNumber,
                        element: \.identityItem?.workPhoneNumber)

                    PassSectionDivider()

                    row(title: IdentityFields.workEmail.title,
                        value: item.workEmail,
                        element: \.identityItem?.workEmail)
                }
                .padding(.vertical, DesignConstant.sectionPadding)
                .roundedEditableSection()
                customFields(item.extraWorkDetails,
                             border: borderColor(for: \.identityItem?.extraWorkDetails))
            }
        } header: {
            sectionTitle(title: "Work details")
        }
    }
}

extension DetailHistoryView {
    func customSections(_ sections: [CustomSection]) -> some View {
        ForEach(sections) { customSection in
            customDetailSection(customSection: customSection)
        }
    }
}

private extension DetailHistoryView {
    func customDetailSection(customSection: CustomSection) -> some View {
        Section {
            customFields(customSection.content,
                         border: customSectionsColor)
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
    func row(title: String,
             value: String,
             element: KeyPath<ItemContent, some Hashable>) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(title)
                    .sectionTitleText()

                Text(value)
                    .foregroundStyle(textColor(for: element).toColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture {
                viewModel.copyValueToClipboard(value: value,
                                               message: title)
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    func customFields(_ fields: [CustomField], border: UIColor) -> some View {
        VStack(spacing: 0) {
            ForEach(fields) { field in
                HStack(spacing: DesignConstant.sectionPadding) {
                    VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                        Text(field.title)
                            .sectionTitleText()

                        Text(field.content)
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
        .roundedDetailSection(borderColor: border)
    }

    var customSectionsColor: UIColor {
        var currentSections: [CustomSection] = []
        var pastSections: [CustomSection] = []
        switch viewModel.itemContentType {
        case .identity:
            currentSections = viewModel.currentRevision.identityItem?.extraSections ?? []
            pastSections = viewModel.pastRevision.identityItem?.extraSections ?? []
        case .sshKey:
            currentSections = viewModel.currentRevision.sshKey?.extraSections ?? []
            pastSections = viewModel.pastRevision.sshKey?.extraSections ?? []
        case .wifi:
            currentSections = viewModel.currentRevision.wifi?.extraSections ?? []
            pastSections = viewModel.pastRevision.wifi?.extraSections ?? []
        case .custom:
            currentSections = viewModel.currentRevision.custom?.sections ?? []
            pastSections = viewModel.pastRevision.custom?.sections ?? []
        default:
            return PassColor.inputBorderNorm
        }
        return currentSections != pastSections ? PassColor.signalWarning : PassColor.inputBorderNorm
    }

    func sectionTitle(title: LocalizedStringKey) -> some View {
        Text(title)
            .foregroundStyle(PassColor.textWeak.toColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, DesignConstant.sectionPadding)
            .padding(.vertical, DesignConstant.sectionPadding)
    }
}
