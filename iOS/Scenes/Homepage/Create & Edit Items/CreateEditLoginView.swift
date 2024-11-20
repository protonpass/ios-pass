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

// swiftlint:disable file_length
import CodeScanner
import Core
import DesignSystem
import Entities
import Factory
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI
import TipKit

struct CreateEditLoginView: View {
    @StateObject private var viewModel: CreateEditLoginViewModel
    @FocusState private var focusedField: Field?
    @State private var lastFocusedField: Field?
    @Namespace private var emailOrUsernameID
    @Namespace private var usernameID
    @Namespace private var emailID
    @Namespace private var passwordID
    @Namespace private var websitesID
    @Namespace private var noteID
    @Namespace private var fileAttachmentsID
    @Namespace private var bottomID

    init(viewModel: CreateEditLoginViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    enum Field: CustomFieldTypes {
        case title, emailOrUsername, email, username, password, totp, websites, note
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
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: DesignConstant.sectionPadding / 2) {
                        FileAttachmentsBanner(isShown: viewModel.showFileAttachmentsBanner,
                                              onTap: {
                                                  viewModel.dismissFileAttachmentsBanner()
                                                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                                      proxy.scrollTo(fileAttachmentsID, anchor: .bottom)
                                                  }
                                              },
                                              onClose: { viewModel.dismissFileAttachmentsBanner() })
                        CreateEditItemTitleSection(title: $viewModel.title,
                                                   focusedField: $focusedField,
                                                   field: .title,
                                                   itemContentType: viewModel.itemContentType(),
                                                   isEditMode: viewModel.mode.isEditMode,
                                                   onSubmit: {
                                                       if viewModel.emailUsernameExpanded {
                                                           focusedField = .email
                                                       } else {
                                                           focusedField = .emailOrUsername
                                                       }
                                                   })
                                                   .padding(.bottom, DesignConstant.sectionPadding / 2)
                        editablePasskeySection
                        readOnlyPasskeySection
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

                        if viewModel.fileAttachmentsEnabled {
                            FileAttachmentsEditSection(files: viewModel.files,
                                                       isUploading: viewModel.isUploadingFile,
                                                       primaryTintColor: viewModel.itemContentType()
                                                           .normMajor2Color,
                                                       secondaryTintColor: viewModel.itemContentType()
                                                           .normMinor1Color,
                                                       onDelete: { viewModel.handleDeleteAttachments() },
                                                       onSelect: { viewModel.handle(method: $0) })
                                .id(fileAttachmentsID)
                        }

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
                    .animation(.default, value: viewModel.emailUsernameExpanded)
                    .animation(.default, value: viewModel.passkeys.count)
                    .animation(.default, value: viewModel.isAlias)
                    .animation(.default, value: viewModel.showFileAttachmentsBanner)
                    .showSpinner(viewModel.loading)
                }
                // swiftformat:disable all
                .onChange(of: focusedField) { focusedField in
                    let id: Namespace.ID?
                    switch focusedField {
                    case .title: id = viewModel.emailUsernameExpanded ? emailID : emailOrUsernameID
                    case .emailOrUsername: id = passwordID
                    case .email: id = usernameID
                    case .username: id = passwordID
                    case .totp: id = websitesID
                    case .note: id = noteID
                    default: id = nil
                    }

                    if let id {
                        withAnimation { proxy.scrollTo(id, anchor: .bottom) }
                    }
                }
                // swiftformat:enable all
                .onChange(of: viewModel.recentlyAddedOrEditedField) { _ in
                    withAnimation {
                        proxy.scrollTo(bottomID, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isSaving) { isSaving in
                if isSaving {
                    focusedField = nil
                }
            }
            .onChange(of: viewModel.emailUsernameExpanded) { _ in
                if !viewModel.username.isEmpty {
                    focusedField = .username
                } else {
                    focusedField = .email
                }
            }
            .onFirstAppear {
                if case .create = viewModel.mode {
                    focusedField = .title
                }
            }
            .toolbar { keyboardToolbar }
            .itemCreateEditSetUp(viewModel)
        }
    }
}

private extension CreateEditLoginView {
    @ToolbarContentBuilder
    var keyboardToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            switch focusedField {
            case .email, .emailOrUsername:
                emailTextFieldToolbar
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

    var emailTextFieldToolbar: some View {
        ScrollView(.horizontal) {
            HStack {
                toolbarButton("Hide my email",
                              image: IconProvider.alias,
                              action: { viewModel.generateAlias() })

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
        HStack {
            toolbarButton("Open camera",
                          image: IconProvider.camera,
                          action: {
                              lastFocusedField = focusedField
                              viewModel.openCodeScanner()
                          })

            PassDivider()

            toolbarButton("Paste",
                          image: IconProvider.squares,
                          action: { viewModel.pasteTotpUriFromClipboard() })
        }
        .animationsDisabled() // Disable animation when switching between toolbars
    }

    var passwordTextFieldToolbar: some View {
        HStack {
            toolbarButton("Generate password",
                          image: IconProvider.arrowsRotate,
                          action: { viewModel.generatePassword() })

            PassDivider()

            toolbarButton("Paste",
                          image: IconProvider.squares,
                          action: { viewModel.pastePasswordFromClipboard() })
        }
        .animationsDisabled()
    }

    func toolbarButton(_ title: LocalizedStringKey,
                       image: UIImage,
                       action: @escaping () -> Void) -> some View {
        Button(action: action) {
            // Use HStack instead of Label because Label's text is not rendered in toolbar
            HStack {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 18, height: 18)
                Text(title)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private extension CreateEditLoginView {
    @ViewBuilder
    var editablePasskeySection: some View {
        if !viewModel.passkeys.isEmpty {
            ForEach(viewModel.passkeys, id: \.keyID) {
                passkeyRow($0)
            }
        }
    }

    func passkeyRow(_ passkey: Passkey) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: PassIcon.passkey)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Passkey")
                    .sectionTitleText() +
                    Text(verbatim: " • ")
                    .sectionTitleText() +
                    Text(verbatim: passkey.domain)
                    .sectionTitleText()

                Text(passkey.userName)
                    .foregroundStyle(PassColor.textWeak.toColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: {
                viewModel.remove(passkey: passkey)
            }, label: {
                ItemDetailSectionIcon(icon: IconProvider.cross)
            })
        }
        .padding(DesignConstant.sectionPadding)
        .roundedEditableSection()
    }

    @ViewBuilder
    var readOnlyPasskeySection: some View {
        if let request = viewModel.passkeyRequest {
            HStack(spacing: DesignConstant.sectionPadding) {
                ItemDetailSectionIcon(icon: PassIcon.passkey)

                VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                    Text("Passkey")
                        .sectionTitleText()

                    Text(request.userName)
                        .foregroundStyle(PassColor.textWeak.toColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(DesignConstant.sectionPadding)
            .roundedEditableSection(backgroundColor: PassColor.backgroundMedium)
        } else {
            EmptyView()
        }
    }
}

private extension CreateEditLoginView {
    var usernamePasswordTOTPSection: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            if !viewModel.email.isEmpty || !viewModel.emailOrUsername.isEmpty, viewModel.isAlias {
                if viewModel.emailUsernameExpanded {
                    pendingAliasRow(expanded: true)
                    PassSectionDivider()
                    usernameRow
                } else {
                    pendingAliasRow(expanded: false)
                }
            } else {
                if viewModel.emailUsernameExpanded {
                    emailRow
                    PassSectionDivider()
                    usernameRow
                } else {
                    emailOrUsernameRow
                }
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

    var expandableEmailIcon: some View {
        ZStack(alignment: .topTrailing) {
            if #available(iOS 17, *) {
                ItemDetailSectionIcon(icon: IconProvider.envelope)
                    .buttonEmbeded {
                        viewModel.expandEmailAndUsername()
                    }
                    .popoverTip(UsernameTip())
            } else {
                ItemDetailSectionIcon(icon: IconProvider.envelope)
                    .buttonEmbeded {
                        viewModel.expandEmailAndUsername()
                    }
            }

            Image(uiImage: IconProvider.plus)
                .resizable()
                .renderingMode(.template)
                .frame(width: 9, height: 9)
                .foregroundStyle(PassColor.loginInteractionNormMajor2.toColor)
                .padding(2)
                .background(PassColor.loginInteractionNormMinor1.toColor)
                .clipShape(.circle)
                .overlay(Circle()
                    .stroke(UIColor.secondarySystemGroupedBackground.toColor, lineWidth: 2))
                .offset(x: 5, y: -2)
        }
    }

    var emailOrUsernameRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            expandableEmailIcon

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Email or username")
                    .editableSectionTitleText(for: viewModel.emailOrUsername)

                TrimmingTextField("Add email or username", text: $viewModel.emailOrUsername)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .emailOrUsername)
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .keyboardType(.emailAddress)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ClearTextButton(text: $viewModel.emailOrUsername,
                            onClear: {
                                viewModel.email = ""
                                viewModel.username = ""
                            })
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .animation(.default, value: viewModel.emailOrUsername.isEmpty)
        .animation(.default, value: focusedField)
        .id(emailOrUsernameID)
    }

    var emailRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.envelope)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Email address")
                    .editableSectionTitleText(for: viewModel.email)

                TrimmingTextField("Add email address", text: $viewModel.email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .keyboardType(.emailAddress)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .username }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ClearTextButton(text: $viewModel.email)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .animation(.default, value: viewModel.email.isEmpty)
        .animation(.default, value: focusedField)
        .id(emailID)
    }

    var usernameRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.user)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Username")
                    .editableSectionTitleText(for: viewModel.username)

                TrimmingTextField("Add username", text: $viewModel.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .username)
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ClearTextButton(text: $viewModel.username)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .animation(.default, value: viewModel.username.isEmpty)
        .animation(.default, value: focusedField)
        .id(usernameID)
    }

    func pendingAliasRow(expanded: Bool) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            if expanded {
                ItemDetailSectionIcon(icon: IconProvider.envelope)
            } else {
                expandableEmailIcon
            }

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Email address")
                    .editableSectionTitleText(for: expanded ? viewModel.email : viewModel.emailOrUsername)
                Text(expanded ? viewModel.email : viewModel.emailOrUsername)
                    .foregroundStyle(PassColor.textNorm.toColor)
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
                             backgroundColor: viewModel.itemContentType().normMinor1Color,
                             accessibilityLabel: "Alias action menu")
            })
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .animation(.default, value: viewModel.email.isEmpty)
    }

    var passwordRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            if let passwordStrength = viewModel.passwordStrength {
                PasswordStrengthIcon(strength: passwordStrength)
            } else {
                ItemDetailSectionIcon(icon: IconProvider.key)
            }

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(viewModel.passwordStrength.sectionTitle(reuseCount: nil))
                    .font(.footnote)
                    .foregroundStyle(viewModel.password.isEmpty ?
                        PassColor.textNorm.toColor : viewModel.passwordStrength.sectionTitleColor)

                SensitiveTextField(text: $viewModel.password,
                                   placeholder: #localized("Add password"),
                                   focusedField: $focusedField,
                                   field: Field.password,
                                   font: .body.monospacedFont(for: viewModel.password),
                                   onSubmit: { focusedField = .totp })
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .submitLabel(.done)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)

            ClearTextButton(text: $viewModel.password)
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
                    .editableSectionTitleText()
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
                    .editableSectionTitleText(for: viewModel.totpUri,
                                              isValid: viewModel.totpUriErrorMessage.isEmpty)

                SensitiveTextField(text: $viewModel.totpUri,
                                   placeholder: #localized("Add 2FA secret"),
                                   focusedField: $focusedField,
                                   field: .totp,
                                   font: .body.monospacedFont(for: viewModel.totpUri),
                                   onSubmit: { focusedField = .websites })
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(PassColor.textNorm.toColor)

                if !viewModel.totpUriErrorMessage.isEmpty {
                    InvalidInputLabel(viewModel.totpUriErrorMessage)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)

            ClearTextButton(text: $viewModel.totpUri)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .animation(.default, value: focusedField)
        .animation(.default, value: viewModel.totpUriErrorMessage.isEmpty)
        .sheet(isPresented: $viewModel.isShowingNoCameraPermissionView) {
            NoCameraPermissionView { viewModel.openSettings() }
        }
        .sheet(isPresented: $viewModel.isShowingCodeScanner) {
            WrappedCodeScannerView { result in
                switch lastFocusedField {
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
                    .editableSectionTitleText(for: viewModel.urls.first?.value)
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
                            .foregroundStyle((isValid(url) ?
                                    PassColor.textNorm : PassColor.signalDanger).toColor)
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
        .contentShape(.rect)
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

// swiftlint:enable file_length
