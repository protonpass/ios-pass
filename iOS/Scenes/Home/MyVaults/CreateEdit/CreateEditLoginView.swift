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
    @State private var isShowingDiscardAlert = false
    @State private var isShowingDeleteAliasAlert = false
    @State private var isShowingScanner = false
    @FocusState private var isFocusedOnTitle: Bool
    @FocusState private var isFocusedOnUsername: Bool
    @FocusState private var isFocusedOnPassword: Bool
    @State private var isFocusedOnOtp = false
    @State private var isFocusedOnURLs = false
    @State private var isFocusedOnNote = false
    @State private var invalidUrls = [String]()

    init(viewModel: CreateEditLoginViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    CreateEditItemTitleSection(isFocused: _isFocusedOnTitle,
                                               title: $viewModel.title,
                                               onSubmit: { isFocusedOnUsername.toggle() })
                    usernamePasswordTOTPSection
                    urlsInputView
                    noteInputView
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .onFirstAppear {
                if case .create = viewModel.mode {
                    isFocusedOnTitle.toggle()
                }
            }
            .toolbar {
                CreateEditItemToolbar(
                    saveButtonTitle: viewModel.isAutoFilling ? "Save & AutoFill" : "Save",
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
                        validateUrls()
                        if invalidUrls.isEmpty {
                            await viewModel.save()
                        }
                    })
            }
            .toolbar { keyboardToolbar }
        }
        .tint(Color(uiColor: viewModel.itemContentType().tintColor))
        .navigationViewStyle(.stack)
        .obsoleteItemAlert(isPresented: $viewModel.isObsolete, onAction: dismiss.callAsFunction)
        .discardChangesAlert(isPresented: $isShowingDiscardAlert, onDiscard: dismiss.callAsFunction)
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

    @ToolbarContentBuilder
    private var keyboardToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            if isFocusedOnUsername {
                Button(action: viewModel.generateAlias) {
                    HStack {
                        Image(uiImage: IconProvider.alias)
                            .resizable()
                            .frame(width: 24, height: 24)
                        Text("Hide my email")
                    }
                }
                .transaction { transaction in
                    transaction.animation = nil
                }
            } else if isFocusedOnPassword {
                Button(action: viewModel.generatePassword) {
                    HStack {
                        Image(uiImage: IconProvider.arrowsRotate)
                            .resizable()
                            .frame(width: 24, height: 24)
                        Text("Generate password")
                    }
                }
                .transaction { transaction in
                    transaction.animation = nil
                }
            }
        }
    }

    private var usernamePasswordTOTPSection: some View {
        VStack(spacing: kItemDetailSectionPadding) {
            usernameRow
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

            Button(action: {
                viewModel.username = ""
            }, label: {
                ItemDetailSectionIcon(icon: IconProvider.cross, color: .textWeak)
            })
        }
        .padding(.horizontal, kItemDetailSectionPadding)
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

            Button(action: {
                viewModel.password = ""
            }, label: {
                ItemDetailSectionIcon(icon: IconProvider.cross, color: .textWeak)
            })
        }
        .padding(.horizontal, kItemDetailSectionPadding)
    }

    private var totpRow: some View {
        HStack {
            ItemDetailSectionIcon(icon: IconProvider.lock, color: .textWeak)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Two Factor Authentication")
                    .sectionTitleText()
                switch viewModel.totpManager.state {
                case .empty:
                    Menu(content: {
                        Button(action: {
                            unfocusAllTextFields()
                            viewModel.pasteTotpUriFromClipboard()
                        }, label: {
                            Label(title: {
                                Text("Paste from clipboard")
                            }, icon: {
                                Image(uiImage: IconProvider.squares)
                            })
                        })

                        Button(action: {
                            isShowingScanner.toggle()
                        }, label: {
                            Label(title: {
                                Text("Open camera")
                            }, icon: {
                                Image(uiImage: IconProvider.camera)
                            })
                        })
                    }, label: {
                        Label("Add", systemImage: "plus")
                    })

                case .loading:
                    ProgressView()

                case .valid(let data):
                    HStack {
                        TOTPText(code: data.code)
                        Spacer()
                        TOTPCircularTimer(data: data.timerData)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture(perform: viewModel.copyTotpCode)

                case .invalid:
                    VStack(alignment: .leading) {
                        Text(viewModel.totpManager.uri)
                            .foregroundColor(.textWeak)
                            .lineLimit(2)
                        Text("Invalid Two Factor Authentication URI.")
                            .foregroundColor(.notificationError)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            switch viewModel.totpManager.state {
            case .empty, .loading:
                EmptyView()
            case .valid, .invalid:
                Button(action: viewModel.totpManager.reset) {
                    ItemDetailSectionIcon(icon: IconProvider.cross, color: .textWeak)
                }
            }
        }
        .padding(.horizontal, kItemDetailSectionPadding)
        .animation(.default, value: viewModel.totpManager.state)
        .sheet(isPresented: $isShowingScanner) {
            WrappedCodeScannerView(tintColor: viewModel.itemContentType().tintColor) { result in
                isShowingScanner = false
                viewModel.handleScanResult(result)
            }
        }
    }

    private var urlsInputView: some View {
        UserInputContainerView(title: "Website address",
                               isFocused: isFocusedOnURLs) {
            UserInputContentURLsView(urls: $viewModel.urls,
                                     isFocused: $isFocusedOnURLs,
                                     invalidUrls: $invalidUrls)
            .opacityReduced(viewModel.isSaving)
        }
    }

    private var noteInputView: some View {
        UserInputContainerView(title: "Note",
                               isFocused: isFocusedOnNote) {
            UserInputContentMultilineView(
                text: $viewModel.note,
                isFocused: $isFocusedOnNote)
            .opacityReduced(viewModel.isSaving)
        }
    }

    private func validateUrls() {
        invalidUrls = viewModel.urls.compactMap { url in
            if url.isEmpty { return nil }
            if URLUtils.Sanitizer.sanitize(url) == nil {
                return url
            }
            return nil
        }
    }

    private func unfocusAllTextFields() {
        isFocusedOnTitle = false
        isFocusedOnUsername = false
        isFocusedOnPassword = false
    }
}

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
