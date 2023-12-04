//
// CreateEditLoginView.swift
// Proton Pass - Created on 07/07/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import CodeScanner
import Core
import DesignSystem
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct CreateEditLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateEditLoginViewModel
    @FocusState private var focusedField: Field?
    @State private var isShowingDiscardAlert = false
    @Namespace private var usernameID
    @Namespace private var passwordID
    @Namespace private var websitesID
    @Namespace private var noteID
    @Namespace private var bottomID

    init(viewModel: CreateEditLoginViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    enum Field: CustomFieldTypes {
        case title, username, password, totp, websites, note
        case custom(CustomFieldUiModel?)

        static func == (lhs: Field, rhs: Field) -> Bool {
            if case let .custom(lhsfield) = lhs,
               case let .custom(rhsfield) = rhs {
                return lhsfield?.id == rhsfield?.id
            } else {
                return lhs.hashValue == rhs.hashValue
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: kItemDetailSectionPadding / 2) {
                        CreateEditItemTitleSection(title: $viewModel.title,
                                                   focusedField: $focusedField,
                                                   field: .title,
                                                   selectedVault: viewModel.selectedVault,
                                                   itemContentType: viewModel.itemContentType(),
                                                   isEditMode: viewModel.mode.isEditMode,
                                                   onChangeVault: viewModel.changeVault,
                                                   onSubmit: { focusedField = .username })
                            .padding(.bottom, kItemDetailSectionPadding / 2)
                        usernamePasswordTOTPSection
                        WebsiteSection(viewModel: viewModel,
                                       focusedField: $focusedField,
                                       field: .websites,
                                       onSubmit: { focusedField = .note })
                            .id(websitesID)
                        NoteEditSection(note: $viewModel.note,
                                        focusedField: $focusedField,
                                        field: .note)
                            .id(noteID)

                        EditCustomFieldSections(focusedField: $focusedField,
                                                focusedCustomField: viewModel.recentlyAddedOrEditedField,
                                                contentType: .login,
                                                uiModels: $viewModel.customFieldUiModels,
                                                canAddMore: viewModel.canAddMoreCustomFields,
                                                onAddMore: viewModel.addCustomField,
                                                onEditTitle: viewModel.editCustomFieldTitle,
                                                onUpgrade: viewModel.upgrade)

                        Spacer()
                            .id(bottomID)
                    }
                    .padding()
                    .animation(.default, value: viewModel.customFieldUiModels.count)
                    .animation(.default, value: viewModel.canAddOrEdit2FAURI)
                    .showSpinner(viewModel.loading)
                }
                .onChange(of: focusedField) { focusedField in
                    let id: Namespace.ID?
                    switch focusedField {
                    case .title: id = usernameID
                    case .username: id = passwordID
                    case .totp: id = websitesID
                    case .note: id = noteID
                    case .custom:
                        id = bottomID
                    default: id = nil
                    }

                    if let id {
                        withAnimation { proxy.scrollTo(id, anchor: .bottom) }
                    }
                }
                .onChange(of: viewModel.recentlyAddedOrEditedField) { _ in
                    withAnimation {
                        proxy.scrollTo(bottomID, anchor: .bottom)
                    }
                }
            }
            .background(Color(uiColor: PassColor.backgroundNorm))
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: viewModel.isSaving) { isSaving in
                if isSaving {
                    focusedField = nil
                }
            }
            .onFirstAppear {
                if case .create = viewModel.mode {
                    if #available(iOS 16, *) {
                        focusedField = .title
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                            focusedField = .title
                        }
                    }
                }
            }
            .toolbar {
                CreateEditItemToolbar(saveButtonTitle: viewModel.saveButtonTitle(),
                                      isSaveable: viewModel.isSaveable,
                                      isSaving: viewModel.isSaving,
                                      itemContentType: viewModel.itemContentType(),
                                      shouldUpgrade: false,
                                      onGoBack: {
                                          if viewModel.didEditSomething {
                                              isShowingDiscardAlert.toggle()
                                          } else {
                                              dismiss()
                                          }
                                      },
                                      onUpgrade: { /* Not applicable */ },
                                      onScan: viewModel.openScanner,
                                      onSave: {
                                          if viewModel.validateURLs() {
                                              viewModel.save()
                                          }
                                      })
            }
            .toolbar { keyboardToolbar }
        }
        .accentColor(Color(uiColor: viewModel.itemContentType().normMajor2Color)) // Remove when dropping iOS 15
        .tint(Color(uiColor: viewModel.itemContentType().normMajor2Color))
        .navigationViewStyle(.stack)
        .obsoleteItemAlert(isPresented: $viewModel.isObsolete, onAction: dismiss.callAsFunction)
        .discardChangesAlert(isPresented: $isShowingDiscardAlert, onDiscard: dismiss.callAsFunction)
        .nonEditableVaultAlert(isPresented: $viewModel.isShowingNonEditableAlert,
                               onDiscard: dismiss.callAsFunction)
    }
}

private extension CreateEditLoginView {
    @ToolbarContentBuilder
    var keyboardToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            if #available(iOS 16, *) {
                switch focusedField {
                case .username:
                    usernameTextFieldToolbar
                case .totp:
                    totpTextFieldToolbar
                case let .custom(model) where model?.customField.type == .totp:
                    totpTextFieldToolbar
                case .password:
                    passwordTextFieldToolbar
                default:
                    EmptyView()
                }
            }
        }
    }

    var usernameTextFieldToolbar: some View {
        ScrollView(.horizontal) {
            HStack {
                Button(action: viewModel.generateAlias) {
                    HStack {
                        toolbarIcon(uiImage: IconProvider.alias)
                        Text("Hide my email")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                PassDivider()
                    .padding(.horizontal)

                Button(action: {
                    viewModel.useRealEmailAddress()
                    if viewModel.password.isEmpty {
                        focusedField = .password
                    } else {
                        focusedField = nil
                    }
                }, label: {
                    Text("Use \(viewModel.emailAddress)")
                        .minimumScaleFactor(0.5)
                })
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .animationsDisabled() // Disable animation when switching between toolbars
        }
    }

    var totpTextFieldToolbar: some View {
        ScrollView(.horizontal) {
            HStack {
                Button(action: viewModel.pasteTotpUriFromClipboard) {
                    HStack {
                        toolbarIcon(uiImage: IconProvider.squares)
                        Text("Paste from clipboard")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                PassDivider()

                Button(action: viewModel.openCodeScanner) {
                    HStack {
                        toolbarIcon(uiImage: IconProvider.camera)
                        Text("Open camera")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .animationsDisabled() // Disable animation when switching between toolbars
        }
    }

    var passwordTextFieldToolbar: some View {
        ScrollView(.horizontal) {
            HStack {
                Button(action: viewModel.pastePasswordFromClipboard) {
                    HStack {
                        toolbarIcon(uiImage: IconProvider.squares)
                        Text("Paste from clipboard")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                PassDivider()

                Button(action: viewModel.generatePassword) {
                    HStack {
                        toolbarIcon(uiImage: IconProvider.arrowsRotate)
                        Text("Generate password")
                    }
                }
            }
        }
        .animationsDisabled()
    }

    func toolbarIcon(uiImage: UIImage) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .frame(width: 18, height: 18)
    }
}

// iOS 15 work around
// All the views and functions in this extension can be removed once we drop iOS 15
private extension CreateEditLoginView {
    @ViewBuilder
    func capsuleButton(icon: UIImage?, title: String, action: @escaping () -> Void) -> some View {
        if let icon {
            CapsuleLabelButton(icon: icon,
                               title: title,
                               titleColor: PassColor.interactionNormMajor2,
                               backgroundColor: PassColor.interactionNormMinor1,
                               maxWidth: nil,
                               action: action)
        } else {
            CapsuleTextButton(title: title,
                              titleColor: PassColor.interactionNormMajor2,
                              backgroundColor: PassColor.interactionNormMinor1,
                              maxWidth: nil,
                              action: action)
        }
    }

    var hideMyEmailButton: some View {
        capsuleButton(icon: IconProvider.alias, title: "Hide my email", action: viewModel.generateAlias)
    }

    var useCurrentEmailButton: some View {
        capsuleButton(icon: nil, title: #localized("Use %@", viewModel.emailAddress)) {
            viewModel.useRealEmailAddress()
            if viewModel.password.isEmpty {
                focusedField = .password
            } else {
                focusedField = nil
            }
        }
    }

    var generatePasswordButton: some View {
        capsuleButton(icon: IconProvider.arrowsRotate,
                      title: "Generate password",
                      action: viewModel.generatePassword)
    }

    var pasteFromClipboardButton: some View {
        capsuleButton(icon: IconProvider.squares,
                      title: "Paste from clipboard",
                      action: viewModel.pasteTotpUriFromClipboard)
    }

    var openCameraButton: some View {
        capsuleButton(icon: IconProvider.camera, title: "Open camera", action: viewModel.openCodeScanner)
    }
}

private extension CreateEditLoginView {
    var usernamePasswordTOTPSection: some View {
        VStack(spacing: kItemDetailSectionPadding) {
            if !viewModel.username.isEmpty, viewModel.isAlias {
                pendingAliasRow
            } else {
                usernameRow
            }
            PassSectionDivider()
            passwordRow
            PassSectionDivider()
            if viewModel.canAddOrEdit2FAURI {
                totpAllowedRow
            } else {
                totpNotAllowedRow
            }
        }
        .padding(.vertical, kItemDetailSectionPadding)
        .roundedEditableSection()
    }

    var usernameRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.user)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Username or email address")
                    .sectionTitleText()
                TextField("Add username or email address", text: $viewModel.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .username)
                    .foregroundColor(Color(uiColor: PassColor.textNorm))
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }

                if #unavailable(iOS 16) {
                    if focusedField == .username {
                        hideMyEmailButton
                        useCurrentEmailButton
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !viewModel.username.isEmpty {
                Button(action: {
                    viewModel.username = ""
                }, label: {
                    ItemDetailSectionIcon(icon: IconProvider.cross)
                })
            }
        }
        .padding(.horizontal, kItemDetailSectionPadding)
        .animation(.default, value: viewModel.username.isEmpty)
        .animation(.default, value: focusedField)
        .id(usernameID)
    }

    var pendingAliasRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.alias)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Username or email address")
                    .sectionTitleText()
                Text(viewModel.username)
                    .foregroundColor(PassColor.textNorm.toColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Menu(content: {
                Button(action: viewModel.generateAlias) {
                    Label(title: { Text("Edit alias") }, icon: { Image(uiImage: IconProvider.pencil) })
                }

                Button(action: viewModel.removeAlias,
                       label: {
                           Label(title: { Text("Remove alias") },
                                 icon: { Image(uiImage: IconProvider.crossCircle) })
                       })
            }, label: {
                CircleButton(icon: IconProvider.threeDotsVertical,
                             iconColor: viewModel.itemContentType().normMajor1Color,
                             backgroundColor: viewModel.itemContentType().normMinor1Color)
            })
        }
        .padding(.horizontal, kItemDetailSectionPadding)
        .animation(.default, value: viewModel.username.isEmpty)
    }

    var passwordRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            if let passwordStrength = viewModel.passwordStrength {
                PasswordStrengthIcon(strength: passwordStrength)
            } else {
                ItemDetailSectionIcon(icon: IconProvider.key)
            }

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text(viewModel.passwordStrength.sectionTitle)
                    .font(.footnote)
                    .foregroundColor(viewModel.passwordStrength.sectionTitleColor)

                SensitiveTextField(text: $viewModel.password,
                                   placeholder: #localized("Add password"),
                                   focusedField: $focusedField,
                                   field: Field.password,
                                   font: .body.monospacedFont(for: viewModel.password),
                                   onSubmit: { focusedField = .totp })
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundColor(Color(uiColor: PassColor.textNorm))
                    .submitLabel(.done)

                if #unavailable(iOS 16) {
                    if focusedField == .password {
                        generatePasswordButton
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())

            if !viewModel.password.isEmpty {
                Button(action: {
                    viewModel.password = ""
                }, label: {
                    ItemDetailSectionIcon(icon: IconProvider.cross)
                })
            }
        }
        .padding(.horizontal, kItemDetailSectionPadding)
        .animation(.default, value: viewModel.password.isEmpty)
        .animation(.default, value: focusedField)
        .animation(.default, value: viewModel.passwordStrength)
        .id(passwordID)
    }

    var totpNotAllowedRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.lock)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("2FA limit reached")
                    .sectionTitleText()
                UpgradeButtonLite(action: viewModel.upgrade)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, kItemDetailSectionPadding)
    }

    var totpAllowedRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.lock)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("2FA secret (TOTP)")
                    .sectionTitleText(isValid: viewModel.totpUriErrorMessage.isEmpty)

                SensitiveTextField(text: $viewModel.totpUri,
                                   placeholder: #localized("Add 2FA secret"),
                                   focusedField: $focusedField,
                                   field: .totp,
                                   font: .body.monospacedFont(for: viewModel.totpUri),
                                   onSubmit: { focusedField = .websites })
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundColor(Color(uiColor: PassColor.textNorm))

                if !viewModel.totpUriErrorMessage.isEmpty {
                    InvalidInputLabel(viewModel.totpUriErrorMessage)
                }

                if #unavailable(iOS 16) {
                    if focusedField == .totp {
                        pasteFromClipboardButton
                        openCameraButton
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())

            if !viewModel.totpUri.isEmpty {
                Button(action: {
                    viewModel.totpUri = ""
                }, label: {
                    ItemDetailSectionIcon(icon: IconProvider.cross)
                })
            }
        }
        .padding(.horizontal, kItemDetailSectionPadding)
        .animation(.default, value: focusedField)
        .animation(.default, value: viewModel.totpUriErrorMessage.isEmpty)
        .sheet(isPresented: $viewModel.isShowingNoCameraPermissionView) {
            NoCameraPermissionView(onOpenSettings: viewModel.openSettings)
        }
        .sheet(isPresented: $viewModel.isShowingCodeScanner) {
            WrappedCodeScannerView { result in
                switch focusedField {
                case .totp:
                    viewModel.handleScanResult(result)
                case let .custom(model) where model?.customField.type == .totp:
                    viewModel.handleScanResult(result, customField: model)
                default:
                    return
                }
            }
        }
    }
}

// MARK: - WebsiteSection

private struct WebsiteSection<Field: Hashable>: View {
    @ObservedObject var viewModel: CreateEditLoginViewModel
    let focusedField: FocusState<Field?>.Binding
    let field: Field
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.earth)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Website")
                    .sectionTitleText()
                VStack(alignment: .leading) {
                    ForEach($viewModel.urls) { $url in
                        HStack {
                            TextField(text: $url.value) {
                                Text(verbatim: "https://")
                            }
                            .focused(focusedField, equals: field)
                            .onChange(of: viewModel.urls) { _ in
                                viewModel.invalidURLs.removeAll()
                            }
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .foregroundColor(Color(uiColor: isValid(url) ?
                                    PassColor.textNorm : PassColor.signalDanger))
                            .onSubmit(onSubmit)

                            if !url.value.isEmpty {
                                Button(action: {
                                    withAnimation {
                                        if viewModel.urls.count == 1 {
                                            url.value = ""
                                        } else {
                                            viewModel.urls.removeAll { $0.id == url.id }
                                        }
                                    }
                                }, label: {
                                    ItemDetailSectionIcon(icon: IconProvider.cross)
                                })
                                .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        if viewModel.urls.count > 1 || viewModel.urls.first?.value.isEmpty == false {
                            PassSectionDivider()
                        }
                    }

                    addUrlButton
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.default, value: viewModel.urls)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(kItemDetailSectionPadding)
        .roundedEditableSection()
        .contentShape(Rectangle())
    }

    private func isValid(_ url: IdentifiableObject<String>) -> Bool {
        !viewModel.invalidURLs.contains { $0 == url.value }
    }

    @ViewBuilder
    private var addUrlButton: some View {
        if viewModel.urls.first?.value.isEmpty == false {
            Button(action: {
                if viewModel.urls.last?.value.isEmpty == false {
                    // Only add new URL when last URL has value to avoid adding blank URLs
                    viewModel.urls.append(.init(value: ""))
                }
            }, label: {
                Label("Add", systemImage: "plus")
            })
            .opacityReduced(viewModel.urls.last?.value.isEmpty == true)
        }
    }
}
