//
//
// CreateEditIdentityView.swift
// Proton Pass - Created on 21/05/2024.
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
import FactoryKit
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

// swiftlint:disable file_length
private enum SectionsSheetState {
    case personal(CreateEditIdentitySection)
    case address(CreateEditIdentitySection)
    case contact(CreateEditIdentitySection)
    case work(CreateEditIdentitySection)

    var title: LocalizedStringKey {
        switch self {
        case .personal:
            "Personal details"
        case .address:
            "Address details"
        case .contact:
            "Contact details"
        case .work:
            "Work details"
        }
    }

    var height: CGFloat {
        switch self {
        case .contact, .personal:
            480
        case .address:
            280
        case .work:
            350
        }
    }

    var section: CreateEditIdentitySection {
        switch self {
        case let .address(section), let .contact(section), let .personal(section), let .work(section):
            section
        }
    }
}

struct CreateEditIdentityView: View {
    @StateObject private var viewModel: CreateEditIdentityViewModel
    @State private var sheetState: SectionsSheetState?
    @FocusState private var focusedField: Field?
    @State private var lastFocusedField: Field?

    init(viewModel: CreateEditIdentityViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    enum Field: CustomFieldTypes {
        case title
        // swiftlint:disable:next todo
        // TODO: implement focus later
//        case fullName
//        case email
//        case phoneNumber
//        case firstName
//        case middleName
//        case lastName
//        case birthdate
//        case gender
//        case organization
//        case streetAddress
//        case zipOrPostalCode
//        case city
//        case stateOrProvince
//        case countryOrRegion
//        case floor
//        case county
        case socialSecurityNumber
//        case passportNumber
//        case licenseNumber
//        case website
//        case xHandle
//        case secondPhoneNumber
//        case linkedIn
//        case reddit
//        case facebook
//        case yahoo
//        case instagram
//        case company
//        case jobTitle
//        case personalWebsite
//        case workPhoneNumber
//        case workEmail
        case custom(CustomField?)

        var customField: CustomField? {
            if case let .custom(customField) = self {
                customField
            } else {
                nil
            }
        }

        static func == (lhs: Field, rhs: Field) -> Bool {
            if case let .custom(lhsfield) = lhs,
               case let .custom(rhsfield) = rhs {
                lhsfield?.id == rhsfield?.id
            } else {
                lhs.hashValue == rhs.hashValue
            }
        }
    }

    var body: some View {
        mainContainer
            .optionalSheet(binding: $sheetState) { state in
                sheetContent(for: state)
                    .presentationDetents([.height(state.height)])
                    .presentationDragIndicator(.visible)
            }
            .navigationStackEmbeded()
            .onAppear {
                focusedField = .title
            }
    }
}

private extension CreateEditIdentityView {
    var mainContainer: some View {
        LazyVStack(spacing: DesignConstant.sectionPadding) {
            FileAttachmentsBanner(isShown: viewModel.showFileAttachmentsBanner,
                                  onTap: { viewModel.dismissFileAttachmentsBanner() },
                                  onClose: { viewModel.dismissFileAttachmentsBanner() })

            CreateEditItemTitleSection(title: $viewModel.title,
                                       focusedField: $focusedField,
                                       field: .title,
                                       itemContentType: viewModel.itemContentType,
                                       isEditMode: viewModel.mode.isEditMode,
                                       onSubmit: {})
                .padding(.vertical, DesignConstant.sectionPadding / 2)

            staticSections
            customSections
            PassSectionDivider()

            if viewModel.canAddMoreCustomFields {
                CapsuleLabelButton(icon: IconProvider.plus,
                                   title: #localized("Add a custom section"),
                                   titleColor: viewModel.itemContentType.normMajor2Color,
                                   backgroundColor: viewModel.itemContentType.normMinor1Color,
                                   height: 55,
                                   action: { viewModel.showAddCustomSectionAlert.toggle() })
            } else {
                Button { viewModel.upgrade() } label: {
                    Label(title: {
                        Text("Upgrade to add custom sections")
                            .font(.callout)
                            .fontWeight(.medium)
                    }, icon: {
                        Image(uiImage: IconProvider.arrowOutSquare)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 16)
                    })
                    .foregroundStyle(ItemContentType.identity.normMajor2Color.toColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, DesignConstant.sectionPadding)
            }

            if viewModel.fileAttachmentsEnabled {
                FileAttachmentsEditSection(files: viewModel.fileUiModels,
                                           isFetching: viewModel.isFetchingAttachedFiles,
                                           fetchError: viewModel.fetchAttachedFilesError,
                                           isUploading: viewModel.isUploadingFile,
                                           handler: viewModel)
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .padding(.bottom, DesignConstant.sectionPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.default, value: viewModel.sections)
        .animation(.default, value: viewModel.extraPersonalDetails)
        .animation(.default, value: viewModel.extraWorkDetails)
        .animation(.default, value: viewModel.extraAddressDetails)
        .animation(.default, value: viewModel.extraContactDetails)
        .animation(.default, value: viewModel.showFileAttachmentsBanner)
        .scrollViewEmbeded(maxWidth: .infinity)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(PassColor.backgroundNorm.toColor, for: .navigationBar)
        .itemCreateEditSetUp(viewModel)
        .toolbar {
            CreateEditKeyboardToolbar(lastFocusedField: $lastFocusedField,
                                      focusedField: focusedField,
                                      onOpenCodeScanner: viewModel.openCodeScanner,
                                      onPasteTotpUri: { viewModel.handlePastingTotpUri(customField: $0) })
        }
    }

    func addMoreButton(_ action: @escaping () -> Void) -> some View {
        CapsuleLabelButton(icon: IconProvider.plus,
                           title: #localized("Add more"),
                           titleColor: viewModel.itemContentType.normMajor2Color,
                           backgroundColor: viewModel.itemContentType.normMinor1Color,
                           maxWidth: nil,
                           action: action)
    }
}

private extension CreateEditIdentityView {
    var staticSections: some View {
        ForEach(viewModel.sections) { section in
            Section(content: {
                switch section.type {
                case BaseIdentitySection.personalDetails:
                    if !section.isCollapsed {
                        personalDetailSection(section)
                    }
                case BaseIdentitySection.address:
                    if !section.isCollapsed {
                        addressDetailSection(section)
                    }
                case BaseIdentitySection.contact:
                    if !section.isCollapsed {
                        contactDetailSection(section)
                    }
                case BaseIdentitySection.workDetail:
                    if !section.isCollapsed {
                        workDetailSection(section)
                    }
                }
            }, header: {
                CustomSectionHeader(title: .localized(section.type.title),
                                    collapsed: section.isCollapsed,
                                    editable: false,
                                    onToggle: { viewModel.toggleCollapsingSection(section) },
                                    onEditTitle: { /* Not applicable */ },
                                    onRemove: { /* Not applicable */ })
            })
        }
    }

    var customSections: some View {
        CreateEditCustomSections(addFieldButtonTitle: #localized("Add more"),
                                 contentType: viewModel.itemContentType,
                                 focusedField: $focusedField,
                                 field: { .custom($0) },
                                 sections: $viewModel.customSections,
                                 onEditSectionTitle: { viewModel.customSectionToRename = $0 },
                                 onEditFieldTitle: viewModel.requestEditCustomFieldTitle,
                                 onAddMoreField: { viewModel.requestAddCustomField(to: $0.id) })
    }
}

// MARK: - Personal Detail Section

private extension CreateEditIdentityView {
    func personalDetailSection(_ section: CreateEditIdentitySection) -> some View {
        VStack(alignment: .leading) {
            VStack(spacing: DesignConstant.sectionPadding) {
                if viewModel.firstName.shouldShow {
                    identityRow(title: IdentityFields.firstName.title,
                                value: $viewModel.firstName.value,
                                inputAutocapitalization: .words)
                    PassSectionDivider()
                }

                if viewModel.middleName.shouldShow {
                    identityRow(title: IdentityFields.middleName.title,
                                value: $viewModel.middleName.value,
                                inputAutocapitalization: .words)
                    PassSectionDivider()
                }

                if viewModel.lastName.shouldShow {
                    identityRow(title: IdentityFields.lastName.title,
                                value: $viewModel.lastName.value,
                                inputAutocapitalization: .words)
                    PassSectionDivider()
                }

                identityRow(title: IdentityFields.fullName.title,
                            value: $viewModel.fullName,
                            inputAutocapitalization: .words)
                PassSectionDivider()

                identityRow(title: IdentityFields.email.title,
                            value: $viewModel.email,
                            keyboardType: .emailAddress)
                PassSectionDivider()

                identityRow(title: IdentityFields.phoneNumber.title,
                            value: $viewModel.phoneNumber,
                            keyboardType: .phonePad)

                if viewModel.birthdate.shouldShow {
                    PassSectionDivider()
                    identityRow(title: IdentityFields.birthdate.title,
                                value: $viewModel.birthdate.value,
                                keyboardType: .numbersAndPunctuation)
                }

                if viewModel.gender.shouldShow {
                    PassSectionDivider()
                    identityRow(title: IdentityFields.gender.title,
                                value: $viewModel.gender.value,
                                inputAutocapitalization: .sentences)
                }

                ForEach($viewModel.extraPersonalDetails) { $field in
                    PassSectionDivider()
                    EditCustomFieldView(focusedField: $focusedField,
                                        field: .custom(field),
                                        contentType: .identity,
                                        value: $field,
                                        showIcon: false,
                                        roundedSection: false,
                                        onEditTitle: { viewModel.requestEditCustomFieldTitle(field) },
                                        onRemove: { viewModel.extraPersonalDetails.remove(field) })
                }
            }
            .padding(.vertical, DesignConstant.sectionPadding)
            .roundedEditableSection()
            addMoreButton {
                sheetState = .personal(section)
            }
        }
    }
}

// MARK: - Address Detail Section

private extension CreateEditIdentityView {
    func addressDetailSection(_ section: CreateEditIdentitySection) -> some View {
        VStack(alignment: .leading) {
            VStack(spacing: DesignConstant.sectionPadding) {
                identityRow(title: IdentityFields.organization.title,
                            value: $viewModel.organization,
                            inputAutocapitalization: .sentences)
                PassSectionDivider()

                identityRow(title: IdentityFields.streetAddress.title,
                            value: $viewModel.streetAddress,
                            inputAutocapitalization: .words)
                PassSectionDivider()

                identityRow(title: IdentityFields.zipOrPostalCode.title,
                            value: $viewModel.zipOrPostalCode,
                            inputAutocapitalization: .characters)
                PassSectionDivider()

                identityRow(title: IdentityFields.city.title,
                            value: $viewModel.city,
                            inputAutocapitalization: .words)
                PassSectionDivider()

                identityRow(title: IdentityFields.stateOrProvince.title,
                            value: $viewModel.stateOrProvince,
                            inputAutocapitalization: .words)
                PassSectionDivider()

                identityRow(title: IdentityFields.countryOrRegion.title,
                            value: $viewModel.countryOrRegion,
                            inputAutocapitalization: .words)

                if viewModel.floor.shouldShow {
                    PassSectionDivider()
                    identityRow(title: IdentityFields.floor.title,
                                value: $viewModel.floor.value)
                }

                if viewModel.county.shouldShow {
                    PassSectionDivider()
                    identityRow(title: IdentityFields.county.title,
                                value: $viewModel.county.value,
                                inputAutocapitalization: .words)
                }

                ForEach($viewModel.extraAddressDetails) { $field in
                    PassSectionDivider()
                    EditCustomFieldView(focusedField: $focusedField,
                                        field: .custom(field),
                                        contentType: .identity,
                                        value: $field,
                                        showIcon: false,
                                        roundedSection: false,
                                        onEditTitle: { viewModel.requestEditCustomFieldTitle(field) },
                                        onRemove: { viewModel.extraAddressDetails.remove(field) })
                }
            }
            .padding(.vertical, DesignConstant.sectionPadding)
            .roundedEditableSection()
            addMoreButton {
                sheetState = .address(section)
            }
        }
    }
}

// MARK: - Contact Detail Section

private extension CreateEditIdentityView {
    func contactDetailSection(_ section: CreateEditIdentitySection) -> some View {
        VStack(alignment: .leading) {
            VStack(spacing: DesignConstant.sectionPadding) {
                identityRow(title: IdentityFields.socialSecurityNumber.title,
                            value: $viewModel.socialSecurityNumber,
                            inputAutocapitalization: .characters,
                            isSensitive: true)
                PassSectionDivider()

                identityRow(title: IdentityFields.passportNumber.title,
                            value: $viewModel.passportNumber,
                            inputAutocapitalization: .characters)
                PassSectionDivider()

                identityRow(title: IdentityFields.licenseNumber.title,
                            value: $viewModel.licenseNumber,
                            inputAutocapitalization: .characters)
                PassSectionDivider()

                identityRow(title: IdentityFields.website.title,
                            value: $viewModel.website)
                PassSectionDivider()

                identityRow(title: IdentityFields.xHandle.title,
                            value: $viewModel.xHandle)
                PassSectionDivider()

                identityRow(title: IdentityFields.secondPhoneNumber.title,
                            value: $viewModel.secondPhoneNumber,
                            keyboardType: .phonePad)

                if viewModel.linkedIn.shouldShow {
                    PassSectionDivider()
                    identityRow(title: IdentityFields.linkedIn.title,
                                value: $viewModel.linkedIn.value)
                }

                if viewModel.reddit.shouldShow {
                    PassSectionDivider()
                    identityRow(title: IdentityFields.reddit.title,
                                value: $viewModel.reddit.value)
                }

                if viewModel.facebook.shouldShow {
                    PassSectionDivider()
                    identityRow(title: IdentityFields.facebook.title,
                                value: $viewModel.facebook.value)
                }

                if viewModel.yahoo.shouldShow {
                    PassSectionDivider()
                    identityRow(title: IdentityFields.yahoo.title,
                                value: $viewModel.yahoo.value)
                }

                if viewModel.instagram.shouldShow {
                    PassSectionDivider()
                    identityRow(title: IdentityFields.instagram.title,
                                value: $viewModel.instagram.value)
                }

                ForEach($viewModel.extraContactDetails) { $field in
                    PassSectionDivider()
                    EditCustomFieldView(focusedField: $focusedField,
                                        field: .custom(field),
                                        contentType: .identity,
                                        value: $field,
                                        showIcon: false,
                                        roundedSection: false,
                                        onEditTitle: { viewModel.requestEditCustomFieldTitle(field) },
                                        onRemove: { viewModel.extraContactDetails.remove(field) })
                }
            }
            .padding(.vertical, DesignConstant.sectionPadding)
            .roundedEditableSection()
            addMoreButton {
                sheetState = .contact(section)
            }
        }
    }
}

// MARK: - Work Detail Section

private extension CreateEditIdentityView {
    func workDetailSection(_ section: CreateEditIdentitySection) -> some View {
        VStack(alignment: .leading) {
            VStack(spacing: DesignConstant.sectionPadding) {
                identityRow(title: IdentityFields.company.title,
                            value: $viewModel.company,
                            inputAutocapitalization: .words)
                PassSectionDivider()

                identityRow(title: IdentityFields.jobTitle.title,
                            value: $viewModel.jobTitle,
                            inputAutocapitalization: .sentences)

                if viewModel.personalWebsite.shouldShow {
                    PassSectionDivider()
                    identityRow(title: IdentityFields.personalWebsite.title,
                                value: $viewModel.personalWebsite.value)
                }

                if viewModel.workPhoneNumber.shouldShow {
                    PassSectionDivider()
                    identityRow(title: IdentityFields.workPhoneNumber.title,
                                value: $viewModel.workPhoneNumber.value,
                                keyboardType: .namePhonePad)
                }

                if viewModel.workEmail.shouldShow {
                    PassSectionDivider()
                    identityRow(title: IdentityFields.workEmail.title,
                                value: $viewModel.workEmail.value)
                }

                ForEach($viewModel.extraWorkDetails) { $field in
                    PassSectionDivider()
                    EditCustomFieldView(focusedField: $focusedField,
                                        field: .custom(field),
                                        contentType: .identity,
                                        value: $field,
                                        showIcon: false,
                                        roundedSection: false,
                                        onEditTitle: { viewModel.requestEditCustomFieldTitle(field) },
                                        onRemove: { viewModel.extraWorkDetails.remove(field) })
                }
            }
            .padding(.vertical, DesignConstant.sectionPadding)
            .roundedEditableSection()
            addMoreButton {
                sheetState = .work(section)
            }
        }
    }
}

// MARK: - Utils

private extension CreateEditIdentityView {
    func identityRow(title: String,
                     subtitle: String? = nil,
                     value: Binding<String>,
                     focusedField: Field? = nil,
                     keyboardType: UIKeyboardType = .default,
                     inputAutocapitalization: TextInputAutocapitalization = .never,
                     isSensitive: Bool = false) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(title)
                    .editableSectionTitleText(for: value.wrappedValue)

                if isSensitive {
                    SensitiveTextField(text: value,
                                       placeholder: subtitle ?? title,
                                       focusedField: $focusedField,
                                       field: Field.socialSecurityNumber)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(inputAutocapitalization)
                        .autocorrectionDisabled()
                        .foregroundStyle(PassColor.textNorm.toColor)
                } else {
                    TextField(subtitle ?? title, text: value)
                        .textInputAutocapitalization(inputAutocapitalization)
                        .keyboardType(keyboardType)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: focusedField)
                        .foregroundStyle(PassColor.textNorm.toColor)
                        .submitLabel(.next)
                        // swiftlint:disable:next todo
                        // TODO: set next focus
                        .onSubmit {}
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ClearTextButton(text: value)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .animation(.default, value: focusedField)
    }

    func sheetContent(for state: SectionsSheetState) -> some View {
        VStack {
            Text("Add field")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(PassColor.textWeak.toColor)
                .frame(maxWidth: .infinity)
                .padding(.top, DesignConstant.sectionPadding)

            Text(state.title)
                .foregroundStyle(PassColor.textNorm.toColor)
                .frame(maxWidth: .infinity)

            switch state {
            case .personal:
                sheetOption("First name", value: $viewModel.firstName)
                PassSectionDivider()

                sheetOption("Middle name", value: $viewModel.middleName)
                PassSectionDivider()

                sheetOption("Last name", value: $viewModel.lastName)
                PassSectionDivider()

                sheetOption("Birthdate", value: $viewModel.birthdate)
                PassSectionDivider()

                sheetOption("Gender", value: $viewModel.gender)
                PassSectionDivider()

            case .address:
                sheetOption("Floor", value: $viewModel.floor)
                PassSectionDivider()

                sheetOption("County", value: $viewModel.county)
                PassSectionDivider()

            case .contact:
                sheetOption("LinkedIn", value: $viewModel.linkedIn)
                PassSectionDivider()

                sheetOption("Reddit", value: $viewModel.reddit)
                PassSectionDivider()

                sheetOption("Facebook", value: $viewModel.facebook)
                PassSectionDivider()

                sheetOption("Yahoo", value: $viewModel.yahoo)
                PassSectionDivider()

                sheetOption("Instagram", value: $viewModel.instagram)
                PassSectionDivider()

            case .work:
                sheetOption("Personal website", value: $viewModel.personalWebsite)
                PassSectionDivider()

                sheetOption("Work phone number", value: $viewModel.workPhoneNumber)
                PassSectionDivider()

                sheetOption("Work email", value: $viewModel.workEmail)
                PassSectionDivider()
            }
            if viewModel.canAddMoreCustomFields {
                Text("Custom field")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, DesignConstant.sectionPadding)
                    .buttonEmbeded {
                        dismissSectionSheet {
                            viewModel.requestAddCustomField(to: state.section.id)
                        }
                    }
            } else {
                Button { viewModel.upgrade() } label: {
                    Label(title: {
                        Text("Upgrade to add custom fields")
                            .font(.callout)
                            .fontWeight(.medium)
                    }, icon: {
                        Image(uiImage: IconProvider.arrowOutSquare)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 16)
                    })
                    .foregroundStyle(ItemContentType.identity.normMajor2Color.toColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, DesignConstant.sectionPadding)
            }
            Spacer()
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, DesignConstant.sectionPadding)
        .background(PassColor.backgroundNorm.toColor)
    }

    func sheetOption(_ title: LocalizedStringKey,
                     value: Binding<HiddenStringValue>) -> some View {
        Text(title)
            .foregroundStyle(PassColor.textNorm.toColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, DesignConstant.sectionPadding)
            .buttonEmbeded {
                dismissSectionSheet {
                    value.wrappedValue.shouldShow.toggle()
                }
            }
            .disabled(value.wrappedValue.shouldShow)
    }

    func dismissSectionSheet(completion: @escaping () -> Void) {
        if #available(iOS 17.0, *) {
            withAnimation {
                sheetState = nil
            } completion: {
                completion()
            }
        } else {
            sheetState = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                completion()
            }
        }
    }
}

private extension BaseIdentitySection {
    var title: LocalizedStringKey {
        switch self {
        case .personalDetails:
            "Personal details"
        case .address:
            "Address details"
        case .contact:
            "Contact details"
        case .workDetail:
            "Work details"
        }
    }
}

// swiftlint:enable file_length
