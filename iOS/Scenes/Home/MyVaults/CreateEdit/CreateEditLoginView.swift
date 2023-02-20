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
    @State private var isShowingScanner = false
    @Namespace private var noteID

    init(viewModel: CreateEditLoginViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ScrollViewReader { value in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        CreateEditItemTitleSection(isFocused: $isFocusedOnTitle,
                                                   title: $viewModel.title,
                                                   onSubmit: { isFocusedOnUsername.toggle() })
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
            .navigationBarTitleDisplayMode(.inline)
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
                        if viewModel.isEmpty {
                            dismiss()
                        } else {
                            isShowingDiscardAlert.toggle()
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
        .accentColor(Color(uiColor: viewModel.itemContentType().tintColor)) // Remove when dropping iOS 15
        .tint(Color(uiColor: viewModel.itemContentType().tintColor))
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
        HStack {
            Button(action: viewModel.generateAlias) {
                HStack {
                    toolbarIcon(uiImage: IconProvider.alias)
                    Text("Hide my email")
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            Divider()

            Button(action: viewModel.useRealEmailAddress) {
                VStack {
                    Text("Use my email address")
                        .font(.callout)
                    Text(viewModel.emailAddress)
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .transaction { transaction in
            // Disable animation when switching between toolbars
            transaction.animation = nil
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

            Divider()

            Button(action: {
                isShowingScanner.toggle()
            }, label: {
                HStack {
                    toolbarIcon(uiImage: IconProvider.camera)
                    Text("Open camera")
                }
            })
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .transaction { transaction in
            // Disable animation when switching between toolbars
            transaction.animation = nil
        }
    }

    private var passwordTextFieldToolbar: some View {
        Button(action: viewModel.generatePassword) {
            HStack {
                toolbarIcon(uiImage: IconProvider.arrowsRotate)
                Text("Generate password")
            }
        }
        .transaction { transaction in
            transaction.animation = nil
        }
    }

    private func toolbarIcon(uiImage: UIImage) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .frame(width: 18, height: 18)
    }

    private var usernamePasswordTOTPSection: some View {
        VStack(spacing: kItemDetailSectionPadding) {
            if viewModel.isAlias {
                createdAliasRow
            } else {
                usernameRow
            }
            Divider()
            passwordRow
            Divider()
            totpRow
        }
        .padding(.vertical, kItemDetailSectionPadding)
        .roundedEditableSection()
    }

    private var usernameRow: some View {
        HStack {
            ItemDetailSectionIcon(icon: IconProvider.user, color: .textWeak)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Username")
                    .sectionTitleText()
                TextField("Add username", text: $viewModel.username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .focused($isFocusedOnUsername)
                    .submitLabel(.next)
                    .onSubmit { isFocusedOnPassword.toggle() }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !viewModel.username.isEmpty {
                Button(action: {
                    viewModel.username = ""
                }, label: {
                    ItemDetailSectionIcon(icon: IconProvider.cross, color: .textWeak)
                })
            }
        }
        .padding(.horizontal, kItemDetailSectionPadding)
        .animation(.default, value: viewModel.username.isEmpty)
    }

    private var createdAliasRow: some View {
        HStack {
            ItemDetailSectionIcon(icon: IconProvider.alias, color: .textWeak)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Username")
                    .sectionTitleText()
                Text(viewModel.username)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Menu(content: {
                Button(
                    role: .destructive,
                    action: { isShowingDeleteAliasAlert.toggle() },
                    label: {
                        Label(title: { Text("Delete alias") }, icon: { Image(uiImage: IconProvider.trash) })
                    })
            }, label: {
                CircleButton(icon: IconProvider.threeDotsVertical,
                             color: viewModel.itemContentType().tintColor,
                             action: {})
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

    private var passwordRow: some View {
        HStack {
            ItemDetailSectionIcon(icon: IconProvider.key, color: .textWeak)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Password")
                    .sectionTitleText()
                TextField("Add password", text: $viewModel.password)
                    .textContentType(.password)
                    .textInputAutocapitalization(.never)
                    .focused($isFocusedOnPassword)
                    .submitLabel(.done)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !viewModel.password.isEmpty {
                Button(action: {
                    viewModel.password = ""
                }, label: {
                    ItemDetailSectionIcon(icon: IconProvider.cross, color: .textWeak)
                })
            }
        }
        .padding(.horizontal, kItemDetailSectionPadding)
        .animation(.default, value: viewModel.password.isEmpty)
    }

    private var totpRow: some View {
        HStack {
            ItemDetailSectionIcon(icon: IconProvider.lock, color: .textWeak)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Two Factor Authentication")
                    .sectionTitleText()
                TextField("otpauth://", text: $viewModel.totpUri)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .focused($isFocusedOnTOTP)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !viewModel.totpUri.isEmpty {
                Button(action: {
                    viewModel.totpUri = ""
                }, label: {
                    ItemDetailSectionIcon(icon: IconProvider.cross, color: .textWeak)
                })
            }
        }
        .padding(.horizontal, kItemDetailSectionPadding)
        .sheet(isPresented: $isShowingScanner) {
            WrappedCodeScannerView(tintColor: viewModel.itemContentType().tintColor) { result in
                isShowingScanner = false
                viewModel.handleScanResult(result)
            }
        }
    }
}

// MARK: - WrappedCodeScannerView
private struct WrappedCodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isGaleryPresented = false
    let tintColor: UIColor
    let completion: (Result<ScanResult, ScanError>) -> Void

    var body: some View {
        NavigationView {
            CodeScannerView(
                codeTypes: [.qr],
                // swiftlint:disable:next line_length
                simulatedData: "otpauth://totp/SimpleLogin:john.doe%40example.com?secret=CKTQQJVWT5IXTGDB&amp;issuer=SimpleLogin",
                isGalleryPresented: $isGaleryPresented,
                completion: completion)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CircleButton(icon: IconProvider.cross,
                                 color: tintColor,
                                 action: dismiss.callAsFunction)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isGaleryPresented.toggle()
                    }, label: {
                        Image(systemName: "photo.on.rectangle.angled")
                            .foregroundColor(Color(uiColor: tintColor))
                    })
                }
            }
        }
    }
}

// MARK: - WebsiteSection
private struct WebsiteSection: View {
    @ObservedObject var viewModel: CreateEditLoginViewModel

    var body: some View {
        HStack {
            ItemDetailSectionIcon(icon: IconProvider.earth, color: .textWeak)

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
                                .disableAutocorrection(true)
                                .foregroundColor(isValid(url) ? .primary : .red)

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
                                    Image(uiImage: IconProvider.cross)
                                })
                                .foregroundColor(.textWeak)
                            }
                        }

                        if viewModel.urls.count > 1 || viewModel.urls.first?.value.isEmpty == false {
                            Divider()
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
                Label("Add another website", systemImage: "plus")
            })
            .opacityReduced(viewModel.urls.last?.value.isEmpty == true)
        }
    }
}
