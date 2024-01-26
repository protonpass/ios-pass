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
import Factory
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct CreateEditLoginView: View {
    private let theme = resolve(\SharedToolingContainer.theme)
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
                lhsfield?.id == rhsfield?.id
            } else {
                lhs.hashValue == rhs.hashValue
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: DesignConstant.sectionPadding / 2) {
                        CreateEditItemTitleSection(title: $viewModel.title,
                                                   focusedField: $focusedField,
                                                   field: .title,
                                                   selectedVault: viewModel.selectedVault,
                                                   itemContentType: viewModel.itemContentType(),
                                                   isEditMode: viewModel.mode.isEditMode,
                                                   onChangeVault: { viewModel.changeVault() },
                                                   onSubmit: { focusedField = .username })
                            .padding(.bottom, DesignConstant.sectionPadding / 2)
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
                                                onAddMore: { viewModel.addCustomField() },
                                                onEditTitle: { model in viewModel.editCustomFieldTitle(model) },
                                                onUpgrade: { viewModel.upgrade() })

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
                    focusedField = .title
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
                                      onScan: { viewModel.openScanner() },
                                      onSave: {
                                          if viewModel.validateURLs() {
                                              viewModel.save()
                                          }
                                      })
            }
            .toolbar { keyboardToolbar }
        }
        .tint(viewModel.itemContentType().normMajor2Color.toColor)
        .navigationViewStyle(.stack)
        .theme(theme)
        .obsoleteItemAlert(isPresented: $viewModel.isObsolete, onAction: dismiss.callAsFunction)
        .discardChangesAlert(isPresented: $isShowingDiscardAlert, onDiscard: dismiss.callAsFunction)
    }
}

private extension CreateEditLoginView {
    @ToolbarContentBuilder
    var keyboardToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
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

    var usernameTextFieldToolbar: some View {
        ScrollView(.horizontal) {
            HStack {
                Button { viewModel.generateAlias() } label: {
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
                Button { viewModel.pasteTotpUriFromClipboard() } label: {
                    HStack {
                        toolbarIcon(uiImage: IconProvider.squares)
                        Text("Paste from clipboard")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                PassDivider()

                Button { viewModel.openCodeScanner() } label: {
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
                Button { viewModel.pastePasswordFromClipboard() } label: {
                    HStack {
                        toolbarIcon(uiImage: IconProvider.squares)
                        Text("Paste from clipboard")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                PassDivider()

                Button { viewModel.generatePassword() } label: {
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

private extension CreateEditLoginView {
    var usernamePasswordTOTPSection: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
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
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedEditableSection()
    }

    var usernameRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.user)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Username or email address")
                    .sectionTitleText()
                TextField("Add username or email address", text: $viewModel.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .username)
                    .foregroundColor(Color(uiColor: PassColor.textNorm))
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
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
        .padding(.horizontal, DesignConstant.sectionPadding)
        .animation(.default, value: viewModel.username.isEmpty)
        .animation(.default, value: focusedField)
        .id(usernameID)
    }

    var pendingAliasRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.alias)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Username or email address")
                    .sectionTitleText()
                Text(viewModel.username)
                    .foregroundColor(PassColor.textNorm.toColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Menu(content: {
                Button { viewModel.generateAlias() } label: {
                    Label(title: { Text("Edit alias") }, icon: { Image(uiImage: IconProvider.pencil) })
                }

                Button { viewModel.removeAlias() }
                    label: {
                        Label(title: { Text("Remove alias") },
                              icon: { Image(uiImage: IconProvider.crossCircle) })
                    }
            }, label: {
                CircleButton(icon: IconProvider.threeDotsVertical,
                             iconColor: viewModel.itemContentType().normMajor1Color,
                             backgroundColor: viewModel.itemContentType().normMinor1Color)
            })
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .animation(.default, value: viewModel.username.isEmpty)
    }

    var passwordRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            if let passwordStrength = viewModel.passwordStrength {
                PasswordStrengthIcon(strength: passwordStrength)
            } else {
                ItemDetailSectionIcon(icon: IconProvider.key)
            }

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(viewModel.passwordStrength.sectionTitle)
                    .font(.footnote)
                    .foregroundColor(viewModel.passwordStrength.sectionTitleColor)

                SensitiveTextField(text: $viewModel.password,
                                   placeholder: #localized("Add password"),
                                   focusedField: $focusedField,
                                   field: Field.password,
                                   font: .body.monospacedFont(for: viewModel.password),
                                   onSubmit: { focusedField = .totp })
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundColor(PassColor.textNorm.toColor)
                    .submitLabel(.done)
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
        .padding(.horizontal, DesignConstant.sectionPadding)
        .animation(.default, value: viewModel.password.isEmpty)
        .animation(.default, value: focusedField)
        .animation(.default, value: viewModel.passwordStrength)
        .id(passwordID)
    }

    var totpNotAllowedRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.lock)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("2FA limit reached")
                    .sectionTitleText()
                UpgradeButtonLite { viewModel.upgrade() }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    var totpAllowedRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.lock)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("2FA secret key (TOTP)")
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
        .padding(.horizontal, DesignConstant.sectionPadding)
        .animation(.default, value: focusedField)
        .animation(.default, value: viewModel.totpUriErrorMessage.isEmpty)
        .sheet(isPresented: $viewModel.isShowingNoCameraPermissionView) {
            NoCameraPermissionView { viewModel.openSettings() }
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
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.earth)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
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
        .padding(DesignConstant.sectionPadding)
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
