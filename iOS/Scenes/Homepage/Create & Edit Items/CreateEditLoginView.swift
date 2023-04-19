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
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct CreateEditLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateEditLoginViewModel
    @FocusState private var isFocusedOnTitle: Bool
    @FocusState private var isFocusedOnUsername: Bool
    @FocusState private var isFocusedOnPassword: Bool
    @FocusState private var isFocusedOnTOTP: Bool
    @FocusState private var isFocusedOnNote: Bool
    @State private var isShowingDiscardAlert = false
    @State private var isShowingDeleteAliasAlert = false
    @Namespace private var noteID

    init(viewModel: CreateEditLoginViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ScrollViewReader { value in
                ScrollView {
                    LazyVStack(spacing: kItemDetailSectionPadding / 2) {
                        CreateEditItemTitleSection(isFocused: $isFocusedOnTitle,
                                                   title: $viewModel.title,
                                                   selectedVault: viewModel.vault,
                                                   itemContentType: viewModel.itemContentType(),
                                                   isEditMode: viewModel.mode.isEditMode,
                                                   onChangeVault: viewModel.changeVault,
                                                   onSubmit: { isFocusedOnUsername.toggle() })
                        .padding(.bottom, kItemDetailSectionPadding / 2)
                        usernamePasswordTOTPSection
                        WebsiteSection(viewModel: viewModel)
                        NoteEditSection(note: $viewModel.note, isFocused: $isFocusedOnNote)
                            .id(noteID)
                        Spacer()
                    }
                    .padding()
                }
                .onChange(of: isFocusedOnNote) { isFocusedOnNote in
                    if isFocusedOnNote {
                        withAnimation {
                            value.scrollTo(noteID, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.note) { _ in
                    withAnimation {
                        value.scrollTo(noteID, anchor: .bottom)
                    }
                }
            }
            .background(Color(uiColor: PassColor.backgroundNorm))
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: viewModel.isSaving) { isSaving in
                if isSaving {
                    isFocusedOnTitle = false
                    isFocusedOnUsername = false
                    isFocusedOnPassword = false
                    isFocusedOnTOTP = false
                    isFocusedOnNote = false
                }
            }
            .onFirstAppear {
                if case .create = viewModel.mode {
                    if #available(iOS 16, *) {
                        isFocusedOnTitle.toggle()
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                            isFocusedOnTitle.toggle()
                        }
                    }
                }
            }
            .toolbar {
                CreateEditItemToolbar(
                    saveButtonTitle: viewModel.saveButtonTitle(),
                    isSaveable: viewModel.isSaveable,
                    isSaving: viewModel.isSaving,
                    itemContentType: viewModel.itemContentType(),
                    onGoBack: {
                        if viewModel.didEditSomething {
                            isShowingDiscardAlert.toggle()
                        } else {
                            dismiss()
                        }
                    },
                    onSave: {
                        if viewModel.validateURLs() {
                            await viewModel.save()
                        }
                    })
            }
            .toolbar { keyboardToolbar }
        }
        .accentColor(Color(uiColor: viewModel.itemContentType().normMajor1Color)) // Remove when dropping iOS 15
        .tint(Color(uiColor: viewModel.itemContentType().normMajor1Color))
        .navigationViewStyle(.stack)
        .obsoleteItemAlert(isPresented: $viewModel.isObsolete, onAction: dismiss.callAsFunction)
        .discardChangesAlert(isPresented: $isShowingDiscardAlert, onDiscard: dismiss.callAsFunction)
    }

    @ToolbarContentBuilder
    private var keyboardToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            if #available(iOS 16, *) {
                if isFocusedOnUsername {
                    usernameTextFieldToolbar
                } else if isFocusedOnTOTP {
                    totpTextFieldToolbar
                } else if isFocusedOnPassword {
                    passwordTextFieldToolbar
                }
            } else {
                // Embed in a ZStack otherwise toolbars are rendered
                // randomly in iOS 15
                ZStack {
                    if isFocusedOnUsername {
                        usernameTextFieldToolbar
                    } else if isFocusedOnTOTP {
                        totpTextFieldToolbar
                    } else if isFocusedOnPassword {
                        passwordTextFieldToolbar
                    } else {
                        Button("") {}
                    }
                }
            }
        }
    }

    private var usernameTextFieldToolbar: some View {
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
                        isFocusedOnPassword = true
                    } else {
                        isFocusedOnUsername = false
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

    private var totpTextFieldToolbar: some View {
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

    private var passwordTextFieldToolbar: some View {
        Button(action: viewModel.generatePassword) {
            HStack {
                toolbarIcon(uiImage: IconProvider.arrowsRotate)
                Text("Generate password")
            }
        }
        .animationsDisabled()
    }

    private func toolbarIcon(uiImage: UIImage) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .frame(width: 18, height: 18)
    }

    private var usernamePasswordTOTPSection: some View {
        VStack(spacing: kItemDetailSectionPadding) {
            if viewModel.isAlias {
                if viewModel.aliasCreationLiteInfo != nil {
                    pendingAliasRow
                } else {
                    createdAliasRow
                }
            } else {
                usernameRow
            }
            PassSectionDivider()
            passwordRow
            PassSectionDivider()
            totpRow
        }
        .padding(.vertical, kItemDetailSectionPadding)
        .roundedEditableSection()
    }

    private var usernameRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.user)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Username")
                    .sectionTitleText()
                TextField("Add username", text: $viewModel.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isFocusedOnUsername)
                    .foregroundColor(Color(uiColor: PassColor.textNorm))
                    .submitLabel(.next)
                    .onSubmit { isFocusedOnPassword.toggle() }
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
    }

    private var createdAliasRow: some View {
        HStack {
            ItemDetailSectionIcon(icon: IconProvider.alias)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Username or email")
                    .sectionTitleText()
                Text(viewModel.username)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Menu(content: {
                Button(
                    role: .destructive,
                    action: { isShowingDeleteAliasAlert.toggle() },
                    label: {
                        Label(title: { Text("Delete alias") },
                              icon: { Image(uiImage: IconProvider.trash) })
                    })
            }, label: {
                CircleButton(icon: IconProvider.threeDotsVertical,
                             iconColor: viewModel.itemContentType().normMajor1Color,
                             backgroundColor: viewModel.itemContentType().normMinor1Color)
            })
        }
        .padding(.horizontal, kItemDetailSectionPadding)
        .animation(.default, value: viewModel.username.isEmpty)
        .alert(
            "Delete alias?",
            isPresented: $isShowingDeleteAliasAlert,
            actions: {
                Button(role: .destructive,
                       action: viewModel.removeAlias,
                       label: { Text("Yes, delete alias") })

                Button(role: .cancel, label: { Text("Cancel") })
            },
            message: {
                Text("The alias will be deleted permanently.")
            })
    }

    private var pendingAliasRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.alias)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Username or email")
                    .sectionTitleText()
                Text(viewModel.username)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Menu(content: {
                Button(action: viewModel.generateAlias) {
                    Label(title: { Text("Edit alias") }, icon: { Image(uiImage: IconProvider.penSquare) })
                }

                Button(
                    role: .destructive,
                    action: viewModel.removeAlias,
                    label: {
                        Label(title: { Text("Remove alias") }, icon: { Image(uiImage: IconProvider.trash) })
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

    private var passwordRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.key)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Password")
                    .sectionTitleText()

                if !viewModel.password.isEmpty, !viewModel.isShowingPassword {
                    Text(String(repeating: "•", count: 20))
                        .sectionContentText()
                } else {
                    TextField("Add password", text: $viewModel.password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFocusedOnPassword)
                        .foregroundColor(Color(uiColor: PassColor.textNorm))
                        .submitLabel(.done)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.default, value: viewModel.isShowingPassword)
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.isShowingPassword = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    isFocusedOnPassword = true
                }
            }

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
    }

    private var totpRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.lock)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("2FA token (TOTP)")
                    .sectionTitleText()

                if !viewModel.totpUri.isEmpty, !viewModel.isShowingTotpUri {
                    Text(String(repeating: "•", count: 20))
                        .sectionContentText()
                } else {
                    TextField("otpauth://", text: $viewModel.totpUri)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFocusedOnTOTP)
                        .foregroundColor(Color(uiColor: PassColor.textNorm))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.isShowingTotpUri = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    isFocusedOnTOTP = true
                }
            }

            if !viewModel.totpUri.isEmpty {
                Button(action: {
                    viewModel.totpUri = ""
                }, label: {
                    ItemDetailSectionIcon(icon: IconProvider.cross)
                })
            }
        }
        .padding(.horizontal, kItemDetailSectionPadding)
        .sheet(isPresented: $viewModel.isShowingNoCameraPermissionView) {
            NoCameraPermissionView(theme: viewModel.preferences.theme,
                                   onOpenSettings: viewModel.openSettings)
        }
        .sheet(isPresented: $viewModel.isShowingCodeScanner) {
            WrappedCodeScannerView(theme: viewModel.preferences.theme) { result in
                viewModel.handleScanResult(result)
            }
        }
    }
}

// MARK: - WrappedCodeScannerView
private struct WrappedCodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isGaleryPresented = false
    let theme: Theme
    let completion: (Result<ScanResult, ScanError>) -> Void

    var body: some View {
        NavigationView {
            CodeScannerView(
                codeTypes: [.qr],
                // swiftlint:disable:next line_length
                simulatedData: "otpauth://totp/SimpleLogin:john.doe%40example.com?secret=CKTQQJVWT5IXTGDB&amp;issuer=SimpleLogin",
                isGalleryPresented: $isGaleryPresented,
                completion: { result in dismiss(); completion(result) })
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CircleButton(icon: IconProvider.cross,
                                 iconColor: PassColor.interactionNormMajor2,
                                 backgroundColor: PassColor.interactionNormMinor1,
                                 action: dismiss.callAsFunction)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isGaleryPresented.toggle()
                    }, label: {
                        Image(systemName: "photo.on.rectangle.angled")
                            .foregroundColor(Color(uiColor: PassColor.interactionNormMajor1))
                    })
                }
            }
        }
        .navigationViewStyle(.stack)
        .theme(theme)
    }
}

// MARK: - WebsiteSection
private struct WebsiteSection: View {
    @ObservedObject var viewModel: CreateEditLoginViewModel

    var body: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.earth)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Website")
                    .sectionTitleText()
                VStack(alignment: .leading) {
                    ForEach($viewModel.urls) { $url in
                        HStack {
                            TextField("https://", text: $url.value)
                                .onChange(of: viewModel.urls) { _ in
                                    viewModel.invalidURLs.removeAll()
                                }
                                .keyboardType(.URL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .foregroundColor(Color(uiColor: isValid(url) ?
                                                       PassColor.textNorm : PassColor.signalDanger))

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