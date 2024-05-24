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

protocol MultipleSheetDisplaying where Self: Equatable {
    // This the none displaying modal enum case. Should always be present
    static var none: Self { get }

    // This is the binding boolean used to toggle the sheet display
    var shouldDisplay: Bool { get set }
}

extension MultipleSheetDisplaying {
    var shouldDisplay: Bool {
        get {
            switch self {
            case .none:
                false
            default:
                true
            }
        }

        set(newValue) {
            self = newValue ? self : .none
        }
    }
}

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

    @State private var isShowingDiscardAlert = false
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
                switch sheetState {
                default:
                    ViewThatFits {
                        sheetContent
                        ScrollView {
                            sheetContent
                        }
                    }.presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                }
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
                                   height: 55) {}
            }
            .padding(.horizontal, DesignConstant.sectionPadding)
            .padding(.bottom, DesignConstant.sectionPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .showSpinner(viewModel.loading)
//            .animation(.default, value: viewModel.link)
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
//                                                  if viewModel.validateURLs(),
//                                                     viewModel.checkEmail() {
//                                                      viewModel.save()
//                                                  }
                                  })
        }
        .discardChangesAlert(isPresented: $isShowingDiscardAlert, onDiscard: dismiss.callAsFunction)
    }
}

private extension CreateEditIdentityView {
    @ViewBuilder
    func sections() -> some View {
        ForEach(Array(viewModel.sections.enumerated()), id: \.element.id) { index, section in
            Section(content: {
                switch index {
                case 0:
                    if !section.isCollapsed {
                        personalDetailSection(section)
                    }
                case 1:
                    if !section.isCollapsed {
                        addressDetailSection(section)
                    }
                case 2:
                    if !section.isCollapsed {
                        contactDetailSection(section)
                    }
                case 3:
                    if !section.isCollapsed {
                        workDetailSection(section)
                    }
                default:
                    EmptyView()
                }
            }, header: {
                header(for: section)
            })
        }
    }

    func header(for section: CreateEditIdentitySection) -> some View {
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
//
                ////                // TODO: Custom field
//                EditCustomFieldSections(focusedField: $focusedField,
//                                        focusedCustomField: viewModel.recentlyAddedOrEditedField,
//                                        contentType: .login,
//                                        uiModels: $viewModel.customFieldUiModels,
//                                        canAddMore: viewModel.canAddMoreCustomFields,
//                                        onAddMore: { viewModel.addCustomField() },
//                                        onEditTitle: { model in viewModel.editCustomFieldTitle(model) },
//                                        onUpgrade: { viewModel.upgrade() })
//
                ForEach($viewModel.extraPersonalDetails) { $field in
                    VStack {
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
//

//                if vie
                //            if !viewModel.email.isEmpty, viewModel.isAlias {
                //                pendingAliasRow
                //            } else {
                //                emailRow
                //            }
                //            if viewModel.showUsernameField {
                //                PassSectionDivider()
                //                usernameRow
                //            }
                //            PassSectionDivider()
                //            passwordRow
                //            PassSectionDivider()
                //            if viewModel.canAddOrEdit2FAURI {
                //                totpAllowedRow
                //            } else {
                //                totpNotAllowedRow
                //            }
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

//
// struct EditCustomFieldSections<Field: CustomFieldTypes>: View {
//    let focusedField: FocusState<Field?>.Binding
//    let focusedCustomField: CustomFieldUiModel?
//    let contentType: ItemContentType
//    @Binding var uiModels: [CustomFieldUiModel]
//    let canAddMore: Bool
//    let onAddMore: () -> Void
//    let onEditTitle: (CustomFieldUiModel) -> Void
//    let onUpgrade: () -> Void
//
//    var body: some View {
//        ForEach($uiModels) { $uiModel in
//            EditCustomFieldView(focusedField: focusedField,
//                                field: .custom(uiModel),
//                                contentType: contentType,
//                                uiModel: $uiModel,
//                                onEditTitle: { onEditTitle(uiModel) },
//                                onRemove: {
//                                    // Work around a crash in later versions of iOS 17
//                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                                        uiModels.removeAll(where: { $0.id == uiModel.id })
//                                    }
//                                })
//        }
//        .onChange(of: focusedCustomField) { newValue in
//            focusedField.wrappedValue = .custom(newValue)
//        }
//
//        if canAddMore {
//            addMoreButton
//        } else {
//            upgradeButton
//        }
//    }
//
//    private var addMoreButton: some View {
//        Button(action: onAddMore) {
//            Label(title: {
//                Text("Add more")
//                    .font(.callout)
//                    .fontWeight(.medium)
//            }, icon: {
//                Image(systemName: "plus")
//            })
//            .foregroundStyle(contentType.normMajor2Color.toColor)
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .padding(.vertical, DesignConstant.sectionPadding)
//    }
//
//    private var upgradeButton: some View {
//        Button(action: onUpgrade) {
//            Label(title: {
//                Text("Upgrade to add custom fields")
//                    .font(.callout)
//                    .fontWeight(.medium)
//            }, icon: {
//                Image(uiImage: IconProvider.arrowOutSquare)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(maxWidth: 16)
//            })
//            .foregroundStyle(contentType.normMajor2Color.toColor)
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .padding(.vertical, DesignConstant.sectionPadding)
//    }
// }

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

                //
                //                // TODO: Custom field
//                EditCustomFieldSections(focusedField: $focusedField,
//                                        focusedCustomField: viewModel.recentlyAddedOrEditedField,
//                                        contentType: .login,
//                                        uiModels: $viewModel.customFieldUiModels,
//                                        canAddMore: viewModel.canAddMoreCustomFields,
//                                        onAddMore: { viewModel.addCustomField() },
//                                        onEditTitle: { model in
//                                            viewModel.editCustomFieldTitle(model)
//                                        },
//                                        onUpgrade: { viewModel.upgrade() })
                //
                //                ForEach(viewModel.extraPersonalDetails) { field in
                //                    PassSectionDivider()
                //                    identityRow(title: field.title,
                //                                subtitle: field.title,
                //                                value: $viewModel.gender.value)
                //                }
                //

                //                if vie
                //            if !viewModel.email.isEmpty, viewModel.isAlias {
                //                pendingAliasRow
                //            } else {
                //                emailRow
                //            }
                //            if viewModel.showUsernameField {
                //                PassSectionDivider()
                //                usernameRow
                //            }
                //            PassSectionDivider()
                //            passwordRow
                //            PassSectionDivider()
                //            if viewModel.canAddOrEdit2FAURI {
                //                totpAllowedRow
                //            } else {
                //                totpNotAllowedRow
                //            }
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
                identityRow(title: "Passpord number",
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

                //
                //                // TODO: Custom field
//                EditCustomFieldSections(focusedField: $focusedField,
//                                        focusedCustomField: viewModel.recentlyAddedOrEditedField,
//                                        contentType: .login,
//                                        uiModels: $viewModel.customFieldUiModels,
//                                        canAddMore: viewModel.canAddMoreCustomFields,
//                                        onAddMore: { viewModel.addCustomField() },
//                                        onEditTitle: { model in
//                                            viewModel.editCustomFieldTitle(model)
//                                        },
//                                        onUpgrade: { viewModel.upgrade() })

                //                ForEach(viewModel.extraPersonalDetails) { field in
                //                    PassSectionDivider()
                //                    identityRow(title: field.title,
                //                                subtitle: field.title,
                //                                value: $viewModel.gender.value)
                //                }
                //

                //                if vie
                //            if !viewModel.email.isEmpty, viewModel.isAlias {
                //                pendingAliasRow
                //            } else {
                //                emailRow
                //            }
                //            if viewModel.showUsernameField {
                //                PassSectionDivider()
                //                usernameRow
                //            }
                //            PassSectionDivider()
                //            passwordRow
                //            PassSectionDivider()
                //            if viewModel.canAddOrEdit2FAURI {
                //                totpAllowedRow
                //            } else {
                //                totpNotAllowedRow
                //            }
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

                //
                //                // TODO: Custom field
//                EditCustomFieldSections(focusedField: $focusedField,
//                                        focusedCustomField: viewModel.recentlyAddedOrEditedField,
//                                        contentType: .identity,
//                                        uiModels: $viewModel.customFieldUiModels,
//                                        canAddMore: viewModel.canAddMoreCustomFields,
//                                        onAddMore: { viewModel.addCustomField() },
//                                        onEditTitle: { model in viewModel.editCustomFieldTitle(model) },
//                                        onUpgrade: { viewModel.upgrade() })

                //                ForEach(viewModel.extraPersonalDetails) { field in
                //                    PassSectionDivider()
                //                    identityRow(title: field.title,
                //                                subtitle: field.title,
                //                                value: $viewModel.gender.value)
                //                }
                //

                //                if vie
                //            if !viewModel.email.isEmpty, viewModel.isAlias {
                //                pendingAliasRow
                //            } else {
                //                emailRow
                //            }
                //            if viewModel.showUsernameField {
                //                PassSectionDivider()
                //                usernameRow
                //            }
                //            PassSectionDivider()
                //            passwordRow
                //            PassSectionDivider()
                //            if viewModel.canAddOrEdit2FAURI {
                //                totpAllowedRow
                //            } else {
                //                totpNotAllowedRow
                //            }
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

//// MARK: - Custom Section
// private extension CreateEditIdentityView {
//    func personalDetailSection () -> some View {
//    }
// }

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

// extension Dictionary {
//    var keysArray: [Key] {
//        Array(keys)
//    }
// }

//
// struct SecurityWeaknessDetailView: View {
//    @StateObject var viewModel: SecurityWeaknessDetailViewModel
//    @State private var collapsedSections = Set<SecuritySectionHeaderKey>()
//    let isSheet: Bool
//
//    var body: some View {
//        mainContainer.if(isSheet) { view in
//            NavigationStack {
//                view
//            }
//        }
//    }
// }
//
// private extension SecurityWeaknessDetailView {
//    var mainContainer: some View {
//        VStack {
//            switch viewModel.state {
//            case .fetching:
//                ProgressView()
//
//            case let .fetched(data):
//                if let subtitleInfo = viewModel.type.subtitleInfo {
//                    Text(subtitleInfo)
//                        .foregroundStyle(PassColor.textNorm.toColor)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .padding(.vertical)
//                }
//
//                if data.isEmpty {
//                    Spacer()
//                    Image(uiImage: PassIcon.securityEmptyState)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 195)
//                    Text(viewModel.nothingWrongMessage)
//                        .foregroundStyle(PassColor.textHint.toColor)
//                        .fontWeight(.medium)
//                        .multilineTextAlignment(.center)
//                    Spacer()
//                    Spacer()
//                } else {
//                    LazyVStack(spacing: 0) {
//                        if viewModel.type.hasSections {
//                            itemsSections(sections: data)
//                        } else {
//                            itemsList(items: data.flatMap(\.value))
//                        }
//                        Spacer()
//                    }
//                }
//
//            case let .error(error):
//                Text(error.localizedDescription)
//                    .foregroundStyle(PassColor.passwordInteractionNormMajor2.toColor)
//                    .frame(maxWidth: .infinity, alignment: .center)
//            }
//        }
//        .padding(.horizontal, DesignConstant.sectionPadding)
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .animation(.default, value: viewModel.state)
//        .animation(.default, value: collapsedSections)
//        .toolbar { toolbarContent }
//        .if(viewModel.state.fetchedObject?.isEmpty == false) { view in
//            view.scrollViewEmbeded(maxWidth: .infinity)
//        }
//        .background(PassColor.backgroundNorm.toColor)
//        .navigationTitle(viewModel.type.title)
//    }
// }
//
//// MARK: - List of Items
//
// private extension SecurityWeaknessDetailView {
//    func itemsSections(sections: [SecuritySectionHeaderKey: [ItemContent]]) -> some View {
//        ForEach(sections.sortedMostWeakness) { key in
//            Section(content: {
//                if !collapsedSections.contains(key), let items = sections[key] {
//                    itemsList(items: items)
//                }
//            }, header: {
//                header(for: key)
//            })
//        }
//    }
//
//    func header(for key: SecuritySectionHeaderKey) -> some View {
//        Label(title: { Text(key.title) },
//              icon: {
//                  if viewModel.type.collapsible {
//                      Image(systemName: collapsedSections.contains(key) ? "chevron.up" : "chevron.down")
//                          .resizable()
//                          .scaledToFit()
//                          .frame(width: 12)
//                  }
//              })
//              .foregroundStyle(PassColor.textWeak.toColor)
//              .frame(maxWidth: .infinity, alignment: .leading)
//              .if(viewModel.type.collapsible) { view in
//                  view
//                      .padding(.top, DesignConstant.sectionPadding)
//                      .buttonEmbeded {
//                          if collapsedSections.contains(key) {
//                              collapsedSections.remove(key)
//                          } else {
//                              collapsedSections.insert(key)
//                          }
//                      }
//              }
//    }
//
//    func itemsList(items: [ItemContent]) -> some View {
//        ForEach(items) { item in
//            itemRow(for: item)
//        }
//    }
//
//    func itemRow(for item: ItemContent) -> some View {
//        Button {
//            viewModel.showDetail(item: item)
//        } label: {
//            GeneralItemRow(thumbnailView: { ItemSquircleThumbnail(data: item.thumbnailData()) },
//                           title: item.title,
//                           description: item.toItemUiModel.description)
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .padding(.vertical, 3)
//        }
//        .buttonStyle(.plain)
//    }
// }
//
// private extension SecurityWeaknessDetailView {
//    @ToolbarContentBuilder
//    var toolbarContent: some ToolbarContent {
//        ToolbarItem(placement: .navigationBarLeading) {
//            CircleButton(icon: isSheet ? IconProvider.chevronDown : IconProvider.chevronLeft,
//                         iconColor: PassColor.interactionNormMajor2,
//                         backgroundColor: PassColor.interactionNormMinor1,
//                         accessibilityLabel: "Close") {
//                viewModel.dismiss(isSheet: isSheet)
//            }
//        }
//    }
// }
//
// struct SecuritySectionHeaderKey: Hashable, Comparable, Identifiable {
//    let id = UUID().uuidString
//    let title: String
//
//    static func < (lhs: SecuritySectionHeaderKey, rhs: SecuritySectionHeaderKey) -> Bool {
//        lhs.title < rhs.title
//    }
// }
//
// private extension SecurityWeakness {
//    var hasSections: Bool {
//        switch self {
//        case .excludedItems, .missing2FA, .weakPasswords:
//            false
//        default:
//            true
//        }
//    }
//
//    var collapsible: Bool {
//        if case .reusedPasswords = self {
//            return true
//        }
//        return false
//    }
// }
//
// private extension [SecuritySectionHeaderKey: [ItemContent]] {
//    var sortedMostWeakness: [SecuritySectionHeaderKey] {
//        self.keys.sorted {
//            (self[$0]?.count ?? 0) > (self[$1]?.count ?? 0)
//        }
//    }
// }

// struct CreateEditIdentityView_Previews: PreviewProvider {
//    static var previews: some View {
//        CreateEditIdentityView()
//    }
// }

//
//
//
////
//// CreateEditLoginView.swift
//// Proton Pass - Created on 07/07/2022.
//// Copyright (c) 2022 Proton Technologies AG
////
//// This file is part of Proton Pass.
////
//// Proton Pass is free software: you can redistribute it and/or modify
//// it under the terms of the GNU General Public License as published by
//// the Free Software Foundation, either version 3 of the License, or
//// (at your option) any later version.
////
//// Proton Pass is distributed in the hope that it will be useful,
//// but WITHOUT ANY WARRANTY; without even the implied warranty of
//// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//// GNU General Public License for more details.
////
//// You should have received a copy of the GNU General Public License
//// along with Proton Pass. If not, see https://www.gnu.org/licenses/.
//
// import CodeScanner
// import Core
// import DesignSystem
// import Entities
// import Factory
// import Macro
// import ProtonCoreUIFoundations
// import Screens
// import SwiftUI
// import TipKit
//
// struct CreateEditLoginView: View {
//    private let theme = resolve(\SharedToolingContainer.theme)
//    @Environment(\.dismiss) private var dismiss
//    @StateObject private var viewModel: CreateEditLoginViewModel
//    @FocusState private var focusedField: Field?
//    @State private var lastFocusedField: Field?
//    @State private var isShowingDiscardAlert = false
//    @Namespace private var usernameID
//    @Namespace private var emailID
//    @Namespace private var passwordID
//    @Namespace private var websitesID
//    @Namespace private var noteID
//    @Namespace private var bottomID
//
//    init(viewModel: CreateEditLoginViewModel) {
//        _viewModel = .init(wrappedValue: viewModel)
//    }
//
//    enum Field: CustomFieldTypes {
//        case title, email, username, password, totp, websites, note
//        case custom(CustomFieldUiModel?)
//
//        static func == (lhs: Field, rhs: Field) -> Bool {
//            if case let .custom(lhsfield) = lhs,
//               case let .custom(rhsfield) = rhs {
//                lhsfield?.id == rhsfield?.id
//            } else {
//                lhs.hashValue == rhs.hashValue
//            }
//        }
//    }
//
//    var body: some View {
//        NavigationStack {
//            ScrollViewReader { proxy in
//                ScrollView {
//                    LazyVStack(spacing: DesignConstant.sectionPadding / 2) {
//                        CreateEditItemTitleSection(title: $viewModel.title,
//                                                   focusedField: $focusedField,
//                                                   field: .title,
//                                                   itemContentType: viewModel.itemContentType(),
//                                                   isEditMode: viewModel.mode.isEditMode,
//                                                   onSubmit: { focusedField = .email })
//                            .padding(.bottom, DesignConstant.sectionPadding / 2)
//                        editablePasskeySection
//                        readOnlyPasskeySection
//                        usernamePasswordTOTPSection
//                        WebsiteSection(viewModel: viewModel,
//                                       focusedField: $focusedField,
//                                       field: .websites,
//                                       onSubmit: { focusedField = .note })
//                            .id(websitesID)
//                        NoteEditSection(note: $viewModel.note,
//                                        focusedField: $focusedField,
//                                        field: .note)
//                            .id(noteID)
//
//                        EditCustomFieldSections(focusedField: $focusedField,
//                                                focusedCustomField: viewModel.recentlyAddedOrEditedField,
//                                                contentType: .login,
//                                                uiModels: $viewModel.customFieldUiModels,
//                                                canAddMore: viewModel.canAddMoreCustomFields,
//                                                onAddMore: { viewModel.addCustomField() },
//                                                onEditTitle: { model in viewModel.editCustomFieldTitle(model) },
//                                                onUpgrade: { viewModel.upgrade() })
//
//                        Spacer()
//                            .id(bottomID)
//                    }
//                    .padding()
//                    .animation(.default, value: viewModel.customFieldUiModels.count)
//                    .animation(.default, value: viewModel.canAddOrEdit2FAURI)
//                    .animation(.default, value: viewModel.showUsernameField)
//                    .animation(.default, value: viewModel.passkeys.count)
//                    .showSpinner(viewModel.loading)
//                }
//                // swiftformat:disable all
//                .onChange(of: focusedField) { focusedField in
//                    let id: Namespace.ID?
//                    switch focusedField {
//                    case .title: id = emailID
//                    case .email: id = viewModel.showUsernameField ? usernameID : passwordID
//                    case .username: id = passwordID
//                    case .totp: id = websitesID
//                    case .note: id = noteID
//                    default: id = nil
//                    }
//
//                    if let id {
//                        withAnimation { proxy.scrollTo(id, anchor: .bottom) }
//                    }
//                }
//                // swiftformat:enable all
//                .onChange(of: viewModel.recentlyAddedOrEditedField) { _ in
//                    withAnimation {
//                        proxy.scrollTo(bottomID, anchor: .bottom)
//                    }
//                }
//            }
//            .background(PassColor.backgroundNorm.toColor)
//            .navigationBarTitleDisplayMode(.inline)
//            .onChange(of: viewModel.isSaving) { isSaving in
//                if isSaving {
//                    focusedField = nil
//                }
//            }
//            .onFirstAppear {
//                if case .create = viewModel.mode {
//                    focusedField = .title
//                }
//            }
//            .toolbar {
//                CreateEditItemToolbar(saveButtonTitle: viewModel.saveButtonTitle(),
//                                      isSaveable: viewModel.isSaveable,
//                                      isSaving: viewModel.isSaving,
//                                      canScanDocuments: viewModel.canScanDocuments,
//                                      vault: viewModel.editableVault,
//                                      itemContentType: viewModel.itemContentType(),
//                                      shouldUpgrade: false,
//                                      onSelectVault: { viewModel.changeVault() },
//                                      onGoBack: { isShowingDiscardAlert.toggle() },
//                                      onUpgrade: { /* Not applicable */ },
//                                      onScan: { viewModel.openScanner() },
//                                      onSave: {
//                                          if viewModel.validateURLs(),
//                                             viewModel.checkEmail() {
//                                              viewModel.save()
//                                          }
//                                      })
//            }
//            .toolbar { keyboardToolbar }
//        }
//        .tint(viewModel.itemContentType().normMajor2Color.toColor)
//        .theme(theme)
//        .obsoleteItemAlert(isPresented: $viewModel.isObsolete, onAction: dismiss.callAsFunction)
//        .discardChangesAlert(isPresented: $isShowingDiscardAlert, onDiscard: dismiss.callAsFunction)
//    }
// }
//
// private extension CreateEditLoginView {
//    @ToolbarContentBuilder
//    var keyboardToolbar: some ToolbarContent {
//        ToolbarItemGroup(placement: .keyboard) {
//            switch focusedField {
//            case .email:
//                emailTextFieldToolbar
//            case .totp:
//                totpTextFieldToolbar
//            case let .custom(model) where model?.customField.type == .totp:
//                totpTextFieldToolbar
//            case .password:
//                passwordTextFieldToolbar
//            default:
//                EmptyView()
//            }
//        }
//    }
//
//    var emailTextFieldToolbar: some View {
//        ScrollView(.horizontal) {
//            HStack {
//                toolbarButton("Hide my email",
//                              image: IconProvider.alias,
//                              action: { viewModel.generateAlias() })
//
//                PassDivider()
//                    .padding(.horizontal)
//
//                Button(action: {
//                    viewModel.useRealEmailAddress()
//                    if viewModel.password.isEmpty {
//                        focusedField = .password
//                    } else {
//                        focusedField = nil
//                    }
//                }, label: {
//                    Text("Use \(viewModel.emailAddress)")
//                        .minimumScaleFactor(0.5)
//                })
//                .frame(maxWidth: .infinity, alignment: .center)
//            }
//            .animationsDisabled() // Disable animation when switching between toolbars
//        }
//    }
//
//    var totpTextFieldToolbar: some View {
//        HStack {
//            toolbarButton("Open camera",
//                          image: IconProvider.camera,
//                          action: {
//                              lastFocusedField = focusedField
//                              viewModel.openCodeScanner()
//                          })
//
//            PassDivider()
//
//            toolbarButton("Paste",
//                          image: IconProvider.squares,
//                          action: { viewModel.pasteTotpUriFromClipboard() })
//        }
//        .animationsDisabled() // Disable animation when switching between toolbars
//    }
//
//    var passwordTextFieldToolbar: some View {
//        HStack {
//            toolbarButton("Generate password",
//                          image: IconProvider.arrowsRotate,
//                          action: { viewModel.generatePassword() })
//
//            PassDivider()
//
//            toolbarButton("Paste",
//                          image: IconProvider.squares,
//                          action: { viewModel.pastePasswordFromClipboard() })
//        }
//        .animationsDisabled()
//    }
//
//    func toolbarButton(_ title: LocalizedStringKey,
//                       image: UIImage,
//                       action: @escaping () -> Void) -> some View {
//        Button(action: action) {
//            // Use HStack instead of Label because Label's text is not rendered in toolbar
//            HStack {
//                Image(uiImage: image)
//                    .resizable()
//                    .frame(width: 18, height: 18)
//                Text(title)
//            }
//        }
//        .frame(maxWidth: .infinity, alignment: .center)
//    }
// }
//
// private extension CreateEditLoginView {
//    @ViewBuilder
//    var editablePasskeySection: some View {
//        if viewModel.passkeys.isEmpty {
//            EmptyView()
//        } else {
//            ForEach(viewModel.passkeys, id: \.keyID) {
//                passkeyRow($0)
//            }
//        }
//    }
//
//    func passkeyRow(_ passkey: Passkey) -> some View {
//        HStack(spacing: DesignConstant.sectionPadding) {
//            ItemDetailSectionIcon(icon: PassIcon.passkey)
//
//            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
//                Text("Passkey")
//                    .sectionTitleText() +
//                    Text(verbatim: " • ")
//                    .sectionTitleText() +
//                    Text(verbatim: passkey.domain)
//                    .sectionTitleText()
//
//                Text(passkey.userName)
//                    .foregroundStyle(PassColor.textWeak.toColor)
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//
//            Button(action: {
//                viewModel.remove(passkey: passkey)
//            }, label: {
//                ItemDetailSectionIcon(icon: IconProvider.cross)
//            })
//        }
//        .padding(DesignConstant.sectionPadding)
//        .roundedEditableSection()
//    }
//
//    @ViewBuilder
//    var readOnlyPasskeySection: some View {
//        if let request = viewModel.passkeyRequest {
//            HStack(spacing: DesignConstant.sectionPadding) {
//                ItemDetailSectionIcon(icon: PassIcon.passkey)
//
//                VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
//                    Text("Passkey")
//                        .sectionTitleText()
//
//                    Text(request.userName)
//                        .foregroundStyle(PassColor.textWeak.toColor)
//                }
//                .frame(maxWidth: .infinity, alignment: .leading)
//            }
//            .padding(DesignConstant.sectionPadding)
//            .roundedEditableSection(backgroundColor: PassColor.backgroundMedium)
//        } else {
//            EmptyView()
//        }
//    }
// }
//
// private extension CreateEditLoginView {
//    var usernamePasswordTOTPSection: some View {
//        VStack(spacing: DesignConstant.sectionPadding) {
//            if !viewModel.email.isEmpty, viewModel.isAlias {
//                pendingAliasRow
//            } else {
//                emailRow
//            }
//            if viewModel.showUsernameField {
//                PassSectionDivider()
//                usernameRow
//            }
//            PassSectionDivider()
//            passwordRow
//            PassSectionDivider()
//            if viewModel.canAddOrEdit2FAURI {
//                totpAllowedRow
//            } else {
//                totpNotAllowedRow
//            }
//        }
//        .padding(.vertical, DesignConstant.sectionPadding)
//        .roundedEditableSection()
//    }
//
//    var emailRow: some View {
//        HStack(spacing: DesignConstant.sectionPadding) {
//            if viewModel.usernameFlagActive {
//                ZStack(alignment: .topTrailing) {
//                    if #available(iOS 17, *) {
//                        ItemDetailSectionIcon(icon: IconProvider.envelope)
//                            .buttonEmbeded {
//                                viewModel.showUsernameField.toggle()
//                            }
//                            .popoverTip(UsernameTip())
//                    } else {
//                        ItemDetailSectionIcon(icon: IconProvider.envelope)
//                            .buttonEmbeded {
//                                viewModel.showUsernameField.toggle()
//                            }
//                    }
//                    Image(uiImage: viewModel.showUsernameField ? IconProvider.minus : IconProvider.plus)
//                        .resizable()
//                        .renderingMode(.template)
//                        .frame(width: 9, height: 9)
//                        .foregroundStyle(PassColor.loginInteractionNormMajor2.toColor)
//                        .padding(2)
//                        .background(PassColor.loginInteractionNormMinor1.toColor)
//                        .clipShape(.circle)
//                        .overlay(/// apply a rounded border
//                            Circle()
//                                .stroke(UIColor.secondarySystemGroupedBackground.toColor, lineWidth: 2))
//                        .offset(x: 5, y: -2)
//                }
//            } else {
//                ItemDetailSectionIcon(icon: IconProvider.envelope)
//            }
//
//            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
//                Text("Email address")
//                    .sectionTitleText()
//
//                TextField("Add email address", text: $viewModel.email)
//                    .textInputAutocapitalization(.never)
//                    .autocorrectionDisabled()
//                    .focused($focusedField, equals: .email)
//                    .foregroundStyle(PassColor.textNorm.toColor)
//                    .submitLabel(.next)
//                    .onSubmit { focusedField = viewModel.showUsernameField ? .username : .password }
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//
//            if !viewModel.email.isEmpty {
//                Button(action: {
//                    viewModel.email = ""
//                }, label: {
//                    ItemDetailSectionIcon(icon: IconProvider.cross)
//                })
//            }
//        }
//        .padding(.horizontal, DesignConstant.sectionPadding)
//        .animation(.default, value: viewModel.email.isEmpty)
//        .animation(.default, value: focusedField)
//        .id(emailID)
//    }
//
//    var usernameRow: some View {
//        HStack(spacing: DesignConstant.sectionPadding) {
//            ItemDetailSectionIcon(icon: IconProvider.user)
//
//            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
//                Text("Username")
//                    .sectionTitleText()
//
//                TextField("Add username", text: $viewModel.username)
//                    .textInputAutocapitalization(.never)
//                    .autocorrectionDisabled()
//                    .focused($focusedField, equals: .username)
//                    .foregroundStyle(PassColor.textNorm.toColor)
//                    .submitLabel(.next)
//                    .onSubmit { focusedField = .password }
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//
//            if !viewModel.username.isEmpty {
//                Button(action: {
//                    viewModel.username = ""
//                }, label: {
//                    ItemDetailSectionIcon(icon: IconProvider.cross)
//                })
//            }
//        }
//        .padding(.horizontal, DesignConstant.sectionPadding)
//        .animation(.default, value: viewModel.username.isEmpty)
//        .animation(.default, value: focusedField)
//        .id(usernameID)
//    }
//
//    var pendingAliasRow: some View {
//        HStack(spacing: DesignConstant.sectionPadding) {
//            ItemDetailSectionIcon(icon: IconProvider.alias)
//
//            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
//                Text("Email address")
//                    .sectionTitleText()
//                Text(viewModel.email)
//                    .foregroundStyle(PassColor.textNorm.toColor)
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//
//            Menu(content: {
//                Button { viewModel.generateAlias() } label: {
//                    Label(title: { Text("Edit alias") }, icon: { Image(uiImage: IconProvider.pencil) })
//                }
//
//                Button { viewModel.removeAlias() }
//                    label: {
//                        Label(title: { Text("Remove alias") },
//                              icon: { Image(uiImage: IconProvider.crossCircle) })
//                    }
//            }, label: {
//                CircleButton(icon: IconProvider.threeDotsVertical,
//                             iconColor: viewModel.itemContentType().normMajor1Color,
//                             backgroundColor: viewModel.itemContentType().normMinor1Color,
//                             accessibilityLabel: "Alias action menu")
//            })
//        }
//        .padding(.horizontal, DesignConstant.sectionPadding)
//        .animation(.default, value: viewModel.email.isEmpty)
//    }
//
//    var passwordRow: some View {
//        HStack(spacing: DesignConstant.sectionPadding) {
//            if let passwordStrength = viewModel.passwordStrength {
//                PasswordStrengthIcon(strength: passwordStrength)
//            } else {
//                ItemDetailSectionIcon(icon: IconProvider.key)
//            }
//
//            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
//                Text(viewModel.passwordStrength.sectionTitle(reuseCount: nil))
//                    .font(.footnote)
//                    .foregroundStyle(viewModel.passwordStrength.sectionTitleColor)
//
//                SensitiveTextField(text: $viewModel.password,
//                                   placeholder: #localized("Add password"),
//                                   focusedField: $focusedField,
//                                   field: Field.password,
//                                   font: .body.monospacedFont(for: viewModel.password),
//                                   onSubmit: { focusedField = .totp })
//                    .keyboardType(.asciiCapable)
//                    .textInputAutocapitalization(.never)
//                    .autocorrectionDisabled()
//                    .foregroundStyle(PassColor.textNorm.toColor)
//                    .submitLabel(.done)
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .contentShape(.rect)
//
//            if !viewModel.password.isEmpty {
//                Button(action: {
//                    viewModel.password = ""
//                }, label: {
//                    ItemDetailSectionIcon(icon: IconProvider.cross)
//                })
//            }
//        }
//        .padding(.horizontal, DesignConstant.sectionPadding)
//        .animation(.default, value: viewModel.password.isEmpty)
//        .animation(.default, value: focusedField)
//        .animation(.default, value: viewModel.passwordStrength)
//        .id(passwordID)
//    }
//
//    var totpNotAllowedRow: some View {
//        HStack(spacing: DesignConstant.sectionPadding) {
//            ItemDetailSectionIcon(icon: IconProvider.lock)
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
//    var totpAllowedRow: some View {
//        HStack(spacing: DesignConstant.sectionPadding) {
//            ItemDetailSectionIcon(icon: IconProvider.lock)
//
//            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
//                Text("2FA secret key (TOTP)")
//                    .sectionTitleText(isValid: viewModel.totpUriErrorMessage.isEmpty)
//
//                SensitiveTextField(text: $viewModel.totpUri,
//                                   placeholder: #localized("Add 2FA secret"),
//                                   focusedField: $focusedField,
//                                   field: .totp,
//                                   font: .body.monospacedFont(for: viewModel.totpUri),
//                                   onSubmit: { focusedField = .websites })
//                    .keyboardType(.URL)
//                    .textInputAutocapitalization(.never)
//                    .autocorrectionDisabled()
//                    .foregroundStyle(PassColor.textNorm.toColor)
//
//                if !viewModel.totpUriErrorMessage.isEmpty {
//                    InvalidInputLabel(viewModel.totpUriErrorMessage)
//                }
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .contentShape(.rect)
//
//            if !viewModel.totpUri.isEmpty {
//                Button(action: {
//                    viewModel.totpUri = ""
//                }, label: {
//                    ItemDetailSectionIcon(icon: IconProvider.cross)
//                })
//            }
//        }
//        .padding(.horizontal, DesignConstant.sectionPadding)
//        .animation(.default, value: focusedField)
//        .animation(.default, value: viewModel.totpUriErrorMessage.isEmpty)
//        .sheet(isPresented: $viewModel.isShowingNoCameraPermissionView) {
//            NoCameraPermissionView { viewModel.openSettings() }
//        }
//        .sheet(isPresented: $viewModel.isShowingCodeScanner) {
//            WrappedCodeScannerView { result in
//                switch lastFocusedField {
//                case .totp:
//                    viewModel.handleScanResult(result)
//                case let .custom(model) where model?.customField.type == .totp:
//                    viewModel.handleScanResult(result, customField: model)
//                default:
//                    return
//                }
//            }
//        }
//    }
// }
//
//// MARK: - WebsiteSection
//
// private struct WebsiteSection<Field: Hashable>: View {
//    @ObservedObject var viewModel: CreateEditLoginViewModel
//    let focusedField: FocusState<Field?>.Binding
//    let field: Field
//    let onSubmit: () -> Void
//
//    var body: some View {
//        HStack(spacing: DesignConstant.sectionPadding) {
//            ItemDetailSectionIcon(icon: IconProvider.earth)
//
//            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
//                Text("Website")
//                    .sectionTitleText()
//                VStack(alignment: .leading) {
//                    ForEach($viewModel.urls) { $url in
//                        HStack {
//                            TextField(text: $url.value) {
//                                Text(verbatim: "https://")
//                            }
//                            .focused(focusedField, equals: field)
//                            .onChange(of: viewModel.urls) { _ in
//                                viewModel.invalidURLs.removeAll()
//                            }
//                            .keyboardType(.URL)
//                            .textInputAutocapitalization(.never)
//                            .autocorrectionDisabled()
//                            .foregroundStyle((isValid(url) ?
//                                    PassColor.textNorm : PassColor.signalDanger).toColor)
//                            .onSubmit(onSubmit)
//
//                            if !url.value.isEmpty {
//                                Button(action: {
//                                    withAnimation {
//                                        if viewModel.urls.count == 1 {
//                                            url.value = ""
//                                        } else {
//                                            viewModel.urls.removeAll { $0.id == url.id }
//                                        }
//                                    }
//                                }, label: {
//                                    ItemDetailSectionIcon(icon: IconProvider.cross)
//                                })
//                                .fixedSize(horizontal: false, vertical: true)
//                            }
//                        }
//
//                        if viewModel.urls.count > 1 || viewModel.urls.first?.value.isEmpty == false {
//                            PassSectionDivider()
//                        }
//                    }
//
//                    addUrlButton
//                }
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .animation(.default, value: viewModel.urls)
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//        }
//        .padding(DesignConstant.sectionPadding)
//        .roundedEditableSection()
//        .contentShape(.rect)
//    }
//
//    private func isValid(_ url: IdentifiableObject<String>) -> Bool {
//        !viewModel.invalidURLs.contains { $0 == url.value }
//    }
//
//    @ViewBuilder
//    private var addUrlButton: some View {
//        if viewModel.urls.first?.value.isEmpty == false {
//            Button(action: {
//                if viewModel.urls.last?.value.isEmpty == false {
//                    // Only add new URL when last URL has value to avoid adding blank URLs
//                    viewModel.urls.append(.init(value: ""))
//                }
//            }, label: {
//                Label("Add", systemImage: "plus")
//            })
//            .opacityReduced(viewModel.urls.last?.value.isEmpty == true)
//        }
//    }
// }

// swiftlint:enable file_length
