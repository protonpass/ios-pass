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
import Factory
import Macro
import ProtonCoreUIFoundations
import SwiftUI

// swiftlint:disable file_length
enum SectionsSheetStates: MultipleSheetDisplaying {
    case none
    case personal(CreateEditIdentitySection)
    case address(CreateEditIdentitySection)
    case contact(CreateEditIdentitySection)
    case work(CreateEditIdentitySection)

    var title: String {
        switch self {
        case .personal:
            "Personal Details"
        case .address:
            "Address Details"
        case .contact:
            "Contact Details"
        case .work:
            "Work Details"
        default:
            ""
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
        default:
            0
        }
    }

    var section: CreateEditIdentitySection? {
        switch self {
        case let .address(section), let .contact(section), let .personal(section), let .work(section):
            section
        default:
            nil
        }
    }
}

struct CreateEditIdentityView: View {
    @StateObject private var viewModel: CreateEditIdentityViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var sheetState: SectionsSheetStates = .none
    @State private var showCustomTitleAlert = false
    @State private var showDeleteCustomSectionAlert = false
    @State private var isShowingDiscardAlert = false
    @State private var username = ""

    @FocusState private var focusedField: Field?

    init(viewModel: CreateEditIdentityViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    enum Field: CustomFieldTypes {
        case title, email, username, password, totp, websites, note
        case custom(CustomFieldUiModel?)

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
            .sheet(isPresented: $sheetState.shouldDisplay) {
                sheetContent
                    .presentationDetents([.height(sheetState.height)])
                    .presentationDragIndicator(.visible)
            }
            .navigationStackEmbeded()
    }
}

private extension CreateEditIdentityView {
    var mainContainer: some View {
        ScrollView {
            LazyVStack(spacing: DesignConstant.sectionPadding) {
                CreateEditItemTitleSection(title: $viewModel.title,
                                           focusedField: $focusedField,
                                           field: .title,
                                           itemContentType: viewModel.itemContentType(),
                                           isEditMode: viewModel.mode.isEditMode,
                                           onSubmit: { focusedField = .email })
                    .padding(.vertical, DesignConstant.sectionPadding / 2)

                sections()
                PassSectionDivider()
                CapsuleLabelButton(icon: IconProvider.plus,
                                   title: "Add a custom section",
                                   titleColor: viewModel.itemContentType().normMajor2Color,
                                   backgroundColor: viewModel.itemContentType().normMinor1Color,
                                   height: 55) {
                    showCustomTitleAlert.toggle()
                }
            }
            .padding(.horizontal, DesignConstant.sectionPadding)
            .padding(.bottom, DesignConstant.sectionPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .showSpinner(viewModel.loading)
            .animation(.default, value: viewModel.sections)
            .scrollViewEmbeded(maxWidth: .infinity)
            .background(PassColor.backgroundNorm.toColor)
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(PassColor.backgroundNorm.toColor,
                               for: .navigationBar)
        }
        .toolbar {
            CreateEditItemToolbar(saveButtonTitle: viewModel.saveButtonTitle(),
                                  isSaveable: true, // viewModel.isSaveable,
                                  isSaving: viewModel.isSaving,
                                  canScanDocuments: viewModel.canScanDocuments,
                                  vault: viewModel.editableVault,
                                  itemContentType: viewModel.itemContentType(),
                                  shouldUpgrade: false,
                                  onSelectVault: { viewModel.changeVault() },
                                  onGoBack: { isShowingDiscardAlert.toggle() },
                                  onUpgrade: { /* Not applicable */ },
                                  onScan: { viewModel.openScanner() },
                                  onSave: {
                                      viewModel.save()
                                  })
        }
        .discardChangesAlert(isPresented: $isShowingDiscardAlert, onDiscard: dismiss.callAsFunction)
        .alert("Custom Section", isPresented: $showCustomTitleAlert) {
            TextField("Title", text: $viewModel.customSectionTitle)
            Button("Add", action: viewModel.addCustomSection)
            Button("Cancel", role: .cancel) { viewModel.reset() }
        } message: {
            Text("Enter a section title")
        }
        .alert("Remove custom section", isPresented: $showDeleteCustomSectionAlert) {
            Button("Delete", role: .destructive, action: viewModel.deleteCustomSection)
            Button("Cancel", role: .cancel) { viewModel.reset() }
        } message: {
            Text("Are you sure you want to delete the following section \(viewModel.sectionToDelete?.title ?? "Unknown")")
        }
    }
}

private extension CreateEditIdentityView {
    @ViewBuilder
    func sections() -> some View {
        ForEach(Array(viewModel.sections.enumerated()), id: \.element.id) { index, section in
            Section(content: {
                switch section.id {
                case BaseIdentitySection.personalDetails.rawValue:
                    if !section.isCollapsed {
                        personalDetailSection(section)
                    }
                case BaseIdentitySection.address.rawValue:
                    if !section.isCollapsed {
                        addressDetailSection(section)
                    }
                case BaseIdentitySection.contact.rawValue:
                    if !section.isCollapsed {
                        contactDetailSection(section)
                    }
                case BaseIdentitySection.workDetail.rawValue:
                    if !section.isCollapsed {
                        workDetailSection(section)
                    }
                default:
                    if !section.isCollapsed {
                        customDetailSection(section, index: index)
                    }
                }
            }, header: {
                header(for: section)
            })
        }
    }

    func header(for section: CreateEditIdentitySection) -> some View {
        HStack(alignment: .center) {
            Label(title: { Text(section.title) },
                  icon: {
                      Image(systemName: section.isCollapsed ? "chevron.down" : "chevron.up")
                          .resizable()
                          .scaledToFit()
                          .frame(width: 12)
                  })
                  .foregroundStyle(PassColor.textWeak.toColor)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .padding(.top, DesignConstant.sectionPadding)
                  .buttonEmbeded {
                      viewModel.toggleCollapsingSection(sectionToToggle: section)
                  }
            Spacer()

            if section.isCustom {
                IconProvider.crossCircle
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .padding(.top, DesignConstant.sectionPadding)
                    .buttonEmbeded {
                        viewModel.sectionToDelete = section
                        showDeleteCustomSectionAlert.toggle()
                    }
            }
        }
    }

    func customDetailSection(_ section: CreateEditIdentitySection, index: Int) -> some View {
        VStack(alignment: .leading) {
            VStack(spacing: DesignConstant.sectionPadding) {
                ForEach(Array(section.content.enumerated()), id: \.element.id) { elementIndex, field in
                    VStack {
                        if elementIndex > 0 {
                            PassSectionDivider()
                        }
                        EditCustomFieldView(focusedField: $focusedField,
                                            field: .custom(field),
                                            contentType: .identity,
                                            uiModel: $viewModel.sections[index].content[elementIndex],
                                            // field,
                                            showIcon: false,
                                            roundedSection: false,
                                            onEditTitle: { viewModel.editCustomFieldTitle(field) },
                                            onRemove: {
                                                // Work around a crash in later versions of iOS 17
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                    viewModel.extraPersonalDetails
                                                        .removeAll(where: { $0.id == field.id })
                                                }
                                            })
                    }
                }
            }
            .if(!section.content.isEmpty) { view in
                view.padding(.vertical, DesignConstant.sectionPadding)
            }
            .roundedEditableSection()
            CapsuleLabelButton(icon: IconProvider.plus,
                               title: "Add more",
                               titleColor: viewModel.itemContentType().normMajor2Color,
                               backgroundColor: viewModel.itemContentType().normMinor1Color,
                               maxWidth: 140) {
                viewModel.addCustomField(to: section)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Personal Detail Section

private extension CreateEditIdentityView {
    func personalDetailSection(_ section: CreateEditIdentitySection) -> some View {
        VStack(alignment: .leading) {
            VStack(spacing: DesignConstant.sectionPadding) {
                if viewModel.firstName.shouldShow {
                    identityRow(title: "First name",
                                subtitle: "First name",
                                value: $viewModel.firstName.value)
                    PassSectionDivider()
                }

                if viewModel.middleName.shouldShow {
                    identityRow(title: "Middle name",
                                subtitle: "Middle name",
                                value: $viewModel.middleName.value)
                    PassSectionDivider()
                }

                if viewModel.lastName.shouldShow {
                    identityRow(title: "Last name",
                                subtitle: "Last name",
                                value: $viewModel.lastName.value)
                    PassSectionDivider()
                }

                identityRow(title: "Full name",
                            subtitle: "Full name",
                            value: $viewModel.fullName)
                PassSectionDivider()
                identityRow(title: "Email",
                            subtitle: "Email",
                            value: $viewModel.email,
                            keyboardType: .emailAddress)
                PassSectionDivider()
                identityRow(title: "Phone number",
                            subtitle: "Phone number",
                            value: $viewModel.phoneNumber,
                            keyboardType: .phonePad)

                if viewModel.birthdate.shouldShow {
                    PassSectionDivider()
                    identityRow(title: "Birthdate",
                                subtitle: "Birthdate",
                                value: $viewModel.birthdate.value)
                }

                if viewModel.gender.shouldShow {
                    PassSectionDivider()

                    identityRow(title: "Gender",
                                subtitle: "Gender",
                                value: $viewModel.gender.value)
                }

                ForEach($viewModel.extraPersonalDetails) { $field in
                    PassSectionDivider()
                    EditCustomFieldView(focusedField: $focusedField,
                                        field: .custom(field),
                                        contentType: .identity,
                                        uiModel: $field,
                                        showIcon: false,
                                        roundedSection: false,
                                        onEditTitle: { viewModel.editCustomFieldTitle(field) },
                                        onRemove: {
                                            // Work around a crash in later versions of iOS 17
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                viewModel.extraPersonalDetails
                                                    .removeAll(where: { $0.id == field.id })
                                            }
                                        })
                }
            }
            .padding(.vertical, DesignConstant.sectionPadding)
            .roundedEditableSection()
            CapsuleLabelButton(icon: IconProvider.plus,
                               title: "Add more",
                               titleColor: viewModel.itemContentType().normMajor2Color,
                               backgroundColor: viewModel.itemContentType().normMinor1Color,
                               maxWidth: 140) { sheetState = .personal(section) }
        }
    }
}

// MARK: - Address Detail Section

private extension CreateEditIdentityView {
    func addressDetailSection(_ section: CreateEditIdentitySection) -> some View {
        VStack(alignment: .leading) {
            VStack(spacing: DesignConstant.sectionPadding) {
                identityRow(title: "Organization",
                            subtitle: "Organization",
                            value: $viewModel.organization)
                PassSectionDivider()
                identityRow(title: "Street address, P.O. box",
                            subtitle: "Street address, P.O. box",
                            value: $viewModel.streetAddress)
                PassSectionDivider()
                identityRow(title: "ZIP or Postal code",
                            subtitle: "ZIP or Postal code",
                            value: $viewModel.zipOrPostalCode,
                            keyboardType: .numberPad)
                PassSectionDivider()

                identityRow(title: "City",
                            subtitle: "City",
                            value: $viewModel.city)
                PassSectionDivider()

                identityRow(title: "State or province",
                            subtitle: "State or province",
                            value: $viewModel.stateOrProvince)
                PassSectionDivider()

                identityRow(title: "Country or Region",
                            subtitle: "Country or Region",
                            value: $viewModel.countryOrRegion)

                if viewModel.floor.shouldShow {
                    PassSectionDivider()

                    identityRow(title: "Floor",
                                subtitle: "Floor",
                                value: $viewModel.floor.value)
                }

                if viewModel.county.shouldShow {
                    PassSectionDivider()

                    identityRow(title: "County",
                                subtitle: "County",
                                value: $viewModel.county.value)
                }

                ForEach($viewModel.extraAddressDetails) { $field in
                    PassSectionDivider()
                    EditCustomFieldView(focusedField: $focusedField,
                                        field: .custom(field),
                                        contentType: .identity,
                                        uiModel: $field,
                                        showIcon: false,
                                        roundedSection: false,
                                        onEditTitle: { viewModel.editCustomFieldTitle(field) },
                                        onRemove: {
                                            // Work around a crash in later versions of iOS 17
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                viewModel.extraPersonalDetails
                                                    .removeAll(where: { $0.id == field.id })
                                            }
                                        })
                }
            }
            .padding(.vertical, DesignConstant.sectionPadding)
            .roundedEditableSection()
            CapsuleLabelButton(icon: IconProvider.plus,
                               title: "Add more",
                               titleColor: viewModel.itemContentType().normMajor2Color,
                               backgroundColor: viewModel.itemContentType().normMinor1Color,
                               maxWidth: 140) { sheetState = .address(section) }
        }
    }
}

// MARK: - Contact Detail Section

private extension CreateEditIdentityView {
    func contactDetailSection(_ section: CreateEditIdentitySection) -> some View {
        VStack(alignment: .leading) {
            VStack(spacing: DesignConstant.sectionPadding) {
                identityRow(title: "Social security number",
                            value: $viewModel.socialSecurityNumber)
                PassSectionDivider()
                identityRow(title: "Passport number",
                            value: $viewModel.passportNumber)
                PassSectionDivider()
                identityRow(title: "License number",
                            value: $viewModel.licenseNumber)
                PassSectionDivider()
                identityRow(title: "Website",
                            value: $viewModel.website)
                PassSectionDivider()
                identityRow(title: "X handle",
                            value: $viewModel.xHandle)
                PassSectionDivider()
                identityRow(title: "Second phone number",
                            value: $viewModel.secondPhoneNumber,
                            keyboardType: .namePhonePad)

                if viewModel.linkedin.shouldShow {
                    PassSectionDivider()
                    identityRow(title: "Linkedin",
                                value: $viewModel.linkedin.value)
                }

                if viewModel.reddit.shouldShow {
                    PassSectionDivider()
                    identityRow(title: "Reddit",
                                value: $viewModel.reddit.value)
                }

                if viewModel.facebook.shouldShow {
                    PassSectionDivider()
                    identityRow(title: "Facebook",
                                value: $viewModel.facebook.value)
                }

                if viewModel.yahoo.shouldShow {
                    PassSectionDivider()
                    identityRow(title: "Yahoo",
                                value: $viewModel.yahoo.value)
                }

                if viewModel.instagram.shouldShow {
                    PassSectionDivider()
                    identityRow(title: "Instagram",
                                value: $viewModel.instagram.value)
                }

                ForEach($viewModel.extraContactDetails) { $field in
                    PassSectionDivider()
                    EditCustomFieldView(focusedField: $focusedField,
                                        field: .custom(field),
                                        contentType: .identity,
                                        uiModel: $field,
                                        showIcon: false,
                                        roundedSection: false,
                                        onEditTitle: { viewModel.editCustomFieldTitle(field) },
                                        onRemove: {
                                            // Work around a crash in later versions of iOS 17
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                viewModel.extraPersonalDetails
                                                    .removeAll(where: { $0.id == field.id })
                                            }
                                        })
                }
            }
            .padding(.vertical, DesignConstant.sectionPadding)
            .roundedEditableSection()
            CapsuleLabelButton(icon: IconProvider.plus,
                               title: "Add more",
                               titleColor: viewModel.itemContentType().normMajor2Color,
                               backgroundColor: viewModel.itemContentType().normMinor1Color,
                               maxWidth: 140) { sheetState = .contact(section) }
        }
    }
}

// MARK: - Work Detail Section

private extension CreateEditIdentityView {
    func workDetailSection(_ section: CreateEditIdentitySection) -> some View {
        VStack(alignment: .leading) {
            VStack(spacing: DesignConstant.sectionPadding) {
                identityRow(title: "Company",
                            value: $viewModel.company)
                PassSectionDivider()
                identityRow(title: "Job title",
                            value: $viewModel.jobTitle)

                if viewModel.personalWebsite.shouldShow {
                    PassSectionDivider()
                    identityRow(title: "Personal website",
                                value: $viewModel.personalWebsite.value)
                }

                if viewModel.workPhoneNumber.shouldShow {
                    PassSectionDivider()
                    identityRow(title: "Work phone number",
                                value: $viewModel.workPhoneNumber.value,
                                keyboardType: .namePhonePad)
                }

                if viewModel.workEmail.shouldShow {
                    PassSectionDivider()
                    identityRow(title: "Work email",
                                value: $viewModel.workEmail.value)
                }

                ForEach($viewModel.extraWorkDetails) { $field in
                    PassSectionDivider()
                    EditCustomFieldView(focusedField: $focusedField,
                                        field: .custom(field),
                                        contentType: .identity,
                                        uiModel: $field,
                                        showIcon: false,
                                        roundedSection: false,
                                        onEditTitle: { viewModel.editCustomFieldTitle(field) },
                                        onRemove: {
                                            // Work around a crash in later versions of iOS 17
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                viewModel.extraPersonalDetails
                                                    .removeAll(where: { $0.id == field.id })
                                            }
                                        })
                }
            }
            .padding(.vertical, DesignConstant.sectionPadding)
            .roundedEditableSection()
            CapsuleLabelButton(icon: IconProvider.plus,
                               title: "Add more",
                               titleColor: viewModel.itemContentType().normMajor2Color,
                               backgroundColor: viewModel.itemContentType().normMinor1Color,
                               maxWidth: 140) { sheetState = .work(section) }
        }
    }
}

// MARK: - Utils

private extension CreateEditIdentityView {
    func identityRow(title: String,
                     subtitle: String? = nil,
                     value: Binding<String>,
                     shouldCapitalize: TextInputAutocapitalization = .never,
                     keyboardType: UIKeyboardType = .asciiCapable) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(title)
                    .sectionTitleText()

                TextField(subtitle ?? title, text: value)
                    .textInputAutocapitalization(.never)
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .username)
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !value.wrappedValue.isEmpty {
                Button(action: {
                    value.wrappedValue = ""
                }, label: {
                    ItemDetailSectionIcon(icon: IconProvider.cross)
                })
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
//            .animation(.default, value: viewModel.username.isEmpty)
//            .animation(.default, value: focusedField)
//            .id(usernameID)
    }

    var sheetContent: some View {
        VStack {
            Text("Add field")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(PassColor.textWeak.toColor)
                .frame(maxWidth: .infinity)
                .padding(.top, DesignConstant.sectionPadding)

            Text(sheetState.title)
                .foregroundStyle(PassColor.textNorm.toColor)
                .frame(maxWidth: .infinity)

            switch sheetState {
            case .personal:
                Text("First name")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, DesignConstant.sectionPadding)
                    .buttonEmbeded {
                        viewModel.firstName.shouldShow.toggle()
                    }
                    .disabled(viewModel.firstName.shouldShow)
                PassSectionDivider()

                Text("Middle name")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, DesignConstant.sectionPadding)
                    .buttonEmbeded {
                        viewModel.middleName.shouldShow.toggle()
                    }
                    .disabled(viewModel.middleName.shouldShow)
                PassSectionDivider()

                Text("Lastname name")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, DesignConstant.sectionPadding)
                    .buttonEmbeded {
                        viewModel.lastName.shouldShow.toggle()
                    }
                    .disabled(viewModel.lastName.shouldShow)
                PassSectionDivider()

                Text("Birthdate")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, DesignConstant.sectionPadding)
                    .buttonEmbeded {
                        viewModel.birthdate.shouldShow.toggle()
                    }
                    .disabled(viewModel.birthdate.shouldShow)
                PassSectionDivider()

                Text("Gender")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, DesignConstant.sectionPadding)
                    .buttonEmbeded {
                        viewModel.gender.shouldShow.toggle()
                    }
                    .disabled(viewModel.gender.shouldShow)

                PassSectionDivider()
            case .address:
                Text("Floor")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, DesignConstant.sectionPadding)
                    .buttonEmbeded {
                        viewModel.floor.shouldShow.toggle()
                    }
                    .disabled(viewModel.floor.shouldShow)

                PassSectionDivider()

                Text("County")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, DesignConstant.sectionPadding)
                    .buttonEmbeded {
                        viewModel.county.shouldShow.toggle()
                    }
                    .disabled(viewModel.county.shouldShow)

                PassSectionDivider()

            case .contact:
                Text("Linkedin")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, DesignConstant.sectionPadding)
                    .buttonEmbeded {
                        viewModel.linkedin.shouldShow.toggle()
                    }
                    .disabled(viewModel.linkedin.shouldShow)

                PassSectionDivider()

                Text("Reddit")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, DesignConstant.sectionPadding)
                    .buttonEmbeded {
                        viewModel.reddit.shouldShow.toggle()
                    }
                    .disabled(viewModel.reddit.shouldShow)

                PassSectionDivider()

                Text("Facebook")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, DesignConstant.sectionPadding)
                    .buttonEmbeded {
                        viewModel.facebook.shouldShow.toggle()
                    }
                    .disabled(viewModel.facebook.shouldShow)

                PassSectionDivider()

                Text("Yahoo")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, DesignConstant.sectionPadding)
                    .buttonEmbeded {
                        viewModel.yahoo.shouldShow.toggle()
                    }
                    .disabled(viewModel.yahoo.shouldShow)

                PassSectionDivider()

                Text("Instagram")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, DesignConstant.sectionPadding)
                    .buttonEmbeded {
                        viewModel.instagram.shouldShow.toggle()
                    }
                    .disabled(viewModel.instagram.shouldShow)

                PassSectionDivider()

            case .work:

                Text("Personal website")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, DesignConstant.sectionPadding)
                    .buttonEmbeded {
                        viewModel.personalWebsite.shouldShow.toggle()
                    }
                    .disabled(viewModel.personalWebsite.shouldShow)

                PassSectionDivider()
                Text("Work phone number")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, DesignConstant.sectionPadding)
                    .buttonEmbeded {
                        viewModel.workPhoneNumber.shouldShow.toggle()
                    }
                    .disabled(viewModel.workPhoneNumber.shouldShow)

                PassSectionDivider()
                Text("Work email")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, DesignConstant.sectionPadding)
                    .buttonEmbeded {
                        viewModel.workEmail.shouldShow.toggle()
                    }
                    .disabled(viewModel.workEmail.shouldShow)

                PassSectionDivider()
            default:
                EmptyView()
            }
            Text("Custom field")
                .foregroundStyle(PassColor.textNorm.toColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, DesignConstant.sectionPadding)
                .buttonEmbeded {
                    if let section = sheetState.section {
                        viewModel.addCustomField(to: section)
                    }
                }
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, DesignConstant.sectionPadding)
        .background(PassColor.backgroundNorm.toColor)
    }
}

// swiftlint:enable file_length
