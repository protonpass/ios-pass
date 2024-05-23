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

struct CreateEditIdentityView: View {
    @StateObject private var viewModel: CreateEditIdentityViewModel
    @Environment(\.dismiss) private var dismiss

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
            .navigationStackEmbeded()
    }
}

private extension CreateEditIdentityView {
    var mainContainer: some View {
        ScrollView {
            LazyVStack(spacing: DesignConstant.sectionPadding / 2) {
                CreateEditItemTitleSection(title: $viewModel.title,
                                           focusedField: $focusedField,
                                           field: .title,
                                           itemContentType: viewModel.itemContentType(),
                                           isEditMode: viewModel.mode.isEditMode,
                                           onSubmit: { focusedField = .email })
                    .padding(.vertical, DesignConstant.sectionPadding / 2)

                sections()
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
    func sections() -> some View {
        ForEach(viewModel.sections.sortedKey) { key in
            Section(content: {
                if !viewModel.collapsedSections.contains(key), let items = viewModel.sections[key] {
//                    switch viewModel.sections[key] {
//                    case .
//                    }
                    personalDetailSection()
//                    Text("test")
//                    itemsList(items: items)
                }
            }, header: {
                header(for: key)
            })
        }
    }

    func header(for key: IdentitySectionHeaderKey) -> some View {
        Label(title: { Text(key.title) },
              icon: {
                  Image(systemName: viewModel.collapsedSections.contains(key) ? "chevron.up" : "chevron.down")
                      .resizable()
                      .scaledToFit()
                      .frame(width: 12)
              })
              .foregroundStyle(PassColor.textWeak.toColor)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.top, DesignConstant.sectionPadding)
              .buttonEmbeded {
                  if viewModel.collapsedSections.contains(key) {
                      viewModel.collapsedSections.remove(key)
                  } else {
                      viewModel.collapsedSections.insert(key)
                  }
              }
    }
}

// MARK: - Personal Detail Section

private extension CreateEditIdentityView {
    func personalDetailSection() -> some View {
        VStack(alignment: .leading) {
            VStack(spacing: DesignConstant.sectionPadding) {
                identityRow(title: "Full name",
                            subtitle: "Full name",
                            value: $viewModel.fullName)
                PassSectionDivider()
                identityRow(title: "Email",
                            subtitle: "Email",
                            value: $viewModel.fullName,
                            keyboardType: .emailAddress)
                PassSectionDivider()
                identityRow(title: "Phone number",
                            subtitle: "Phone number",
                            value: $viewModel.fullName,
                            keyboardType: .phonePad)
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
                               maxWidth: 140) {}
        }
    }

//        var usernameRow: some View {
//            HStack(spacing: DesignConstant.sectionPadding) {
//                ItemDetailSectionIcon(icon: IconProvider.user)
//
//                VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
//                    Text("Username")
//                        .sectionTitleText()
//
//                    TextField("Add username", text: $viewModel.username)
//                        .textInputAutocapitalization(.never)
//                        .autocorrectionDisabled()
//                        .focused($focusedField, equals: .username)
//                        .foregroundStyle(PassColor.textNorm.toColor)
//                        .submitLabel(.next)
//                        .onSubmit { focusedField = .password }
//                }
//                .frame(maxWidth: .infinity, alignment: .leading)
//
//                if !viewModel.username.isEmpty {
//                    Button(action: {
//                        viewModel.username = ""
//                    }, label: {
//                        ItemDetailSectionIcon(icon: IconProvider.cross)
//                    })
//                }
//            }
//            .padding(.horizontal, DesignConstant.sectionPadding)
//            .animation(.default, value: viewModel.username.isEmpty)
//            .animation(.default, value: focusedField)
//            .id(usernameID)
//        }

    func identityRow(title: String,
                     subtitle: String,
                     value: Binding<String>,
                     shouldCapitalize: TextInputAutocapitalization = .never,
                     keyboardType: UIKeyboardType = .asciiCapable) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(title)
                    .sectionTitleText()

                TextField(subtitle, text: value)
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
}

//// MARK: - Address Detail Section
// private extension CreateEditIdentityView {
//    func personalDetailSection () -> some View {
//    }
// }
//
//// MARK: - Contact Detail Section
// private extension CreateEditIdentityView {
//    func personalDetailSection () -> some View {
//    }
// }
//
//// MARK: - Work Detail Section
// private extension CreateEditIdentityView {
//    func personalDetailSection () -> some View {
//    }
// }
//
//// MARK: - Custom Section
// private extension CreateEditIdentityView {
//    func personalDetailSection () -> some View {
//    }
// }

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
