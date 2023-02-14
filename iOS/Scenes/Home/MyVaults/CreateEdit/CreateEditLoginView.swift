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
                    otpInputView
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

    @ViewBuilder
    private var otpInputView: some View {
        UserInputContainerView(
            title: "Two Factor Authentication",
            isFocused: isFocusedOnOtp,
            content: {
                switch viewModel.totpManager.state {
                case .empty, .loading:
                    UserInputContentSingleLineWithClearButton(
                        text: $viewModel.totpUri,
                        isFocused: $isFocusedOnOtp,
                        placeholder: "",
                        onClear: { viewModel.totpUri = "" })
                    .opacityReduced(viewModel.isSaving)
                case .valid(let data):
                    HStack {
                        Text(data.code)
                        Spacer()
                        TOTPCircularTimer(data: data.timerData)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture(perform: viewModel.copyTotpCode)
                case .invalid:
                    Text("Invalid Two Factor Authentication URI.")
                        .sectionContentText()
                }
            },
            trailingView: {
                switch viewModel.totpManager.state {
                case .loading:
                    EmptyView()
                case .valid:
                    Menu(content: {
                        Button(
                            role: .destructive,
                            action: { viewModel.totpUri = "" },
                            label: {
                                Label(title: {
                                    Text("Delete")
                                }, icon: {
                                    Image(uiImage: IconProvider.crossCircle)
                                })
                            })
                    }, label: {
                        BorderedImageButton(image: IconProvider.threeDotsVertical) {}
                            .frame(width: 48, height: 48)
                            .opacityReduced(viewModel.isSaving)
                    })
                    .animation(.default, value: viewModel.totpManager.state)
                case .empty, .invalid:
                    let image = UIImage(systemName: "qrcode.viewfinder")?.withRenderingMode(.alwaysTemplate)
                    BorderedImageButton(image: image ?? .add,
                                        action: { isShowingScanner.toggle() })
                    .frame(width: 48, height: 48)
                    .opacityReduced(viewModel.isSaving)
                }
            })
        .sheet(isPresented: $isShowingScanner) {
            WrappedCodeScannerView { result in
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
}

private struct WrappedCodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isGaleryPresented = false
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
                    Button(action: dismiss.callAsFunction) {
                        Text("Cancel")
                    }
                    .foregroundColor(Color(.label))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isGaleryPresented.toggle()
                    }, label: {
                        Image(systemName: "photo.on.rectangle.angled")
                            .foregroundColor(Color(.label))
                    })
                }
            }
        }
    }
}
