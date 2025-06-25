//
// OnboardingCreateFirstLoginStep.swift
// Proton Pass - Created on 03/04/2025.
// Copyright (c) 2025 Proton Technologies AG
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
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct OnboardingCreateFirstLoginStep: View {
    @StateObject private var viewModel: OnboardingCreateFirstLoginStepViewModel
    @FocusState private var focusedServiceName
    @Binding var saveable: Bool
    @Binding var topBar: OnboardingView.TopBar

    init(saveable: Binding<Bool>,
         topBar: Binding<OnboardingView.TopBar>,
         shareId: String,
         services: [KnownService],
         onCreate: @escaping (OnboardFirstLoginPayload) -> Void) {
        _saveable = saveable
        _topBar = topBar
        _viewModel = .init(wrappedValue: .init(shareId: shareId,
                                               services: services,
                                               onCreate: onCreate))
    }

    var body: some View {
        ZStack {
            ServiceSelectionView(serviceName: $viewModel.serviceName,
                                 selectedService: $viewModel.selectedService,
                                 suggestions: viewModel.suggestions,
                                 focused: $focusedServiceName).opacity(viewModel.selectedService == nil ? 1 : 0)
            if let selectedService = viewModel.selectedService {
                CreateFirstLoginView(title: $viewModel.title,
                                     email: $viewModel.email,
                                     username: $viewModel.username,
                                     password: $viewModel.password,
                                     website: $viewModel.website,
                                     service: selectedService)
            }
        }
        .animation(.default, value: viewModel.selectedService)
        .tint(PassColor.interactionNorm.toColor)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, DesignConstant.onboardingPadding)
        .onChange(of: viewModel.selectedService) { _ in
            if let selectedService = viewModel.selectedService {
                topBar = .createFirstLogin(selectedService,
                                           onClose: { viewModel.selectedService = nil },
                                           onSave: viewModel.save)
            } else {
                focusedServiceName = true
                topBar = .notNowButton
            }
        }
        .onChange(of: viewModel.saveable) { newValue in
            saveable = newValue
        }
        .onAppear {
            focusedServiceName = true
        }
    }
}

// MARK: - ServiceSelectionView

private struct ServiceSelectionView: View {
    @Binding var serviceName: String
    @Binding var selectedService: KnownService?
    let suggestions: [KnownService]
    let focused: FocusState<Bool>.Binding

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("Create your first login", bundle: .module)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(PassColor.textNorm.toColor)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)

            Text("Which service do you want to create the login for?", bundle: .module)
                .font(.headline)
                .foregroundStyle(PassColor.textWeak.toColor)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .padding(.vertical, DesignConstant.onboardingPadding)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Service", bundle: .module)
                    .foregroundStyle(PassColor.textNorm.toColor)

                TextField("E.g. LinkedIn", text: $serviceName)
                    .autocorrectionDisabled()
                    .focused(focused)
                    .foregroundStyle(PassColor.textNorm.toColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignConstant.sectionPadding)
            .roundedEditableSection(backgroundColor: .clear)

            ScrollView {
                VStack {
                    ForEach(suggestions, id: \.name) { service in
                        row(for: service)
                        if service != suggestions.last {
                            PassDivider()
                        }
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, DesignConstant.sectionPadding)
            }
            .animation(.default, value: suggestions)
            .padding(.top, DesignConstant.sectionPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, DesignConstant.onboardingPadding)
    }

    private func row(for service: KnownService) -> some View {
        Label(title: {
            name(for: service)
                .foregroundStyle(PassColor.textNorm.toColor)
        }, icon: {
            KnownServiceThumbnail(service: service)
        })
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .onTapGesture {
            selectedService = service
        }
    }

    private func name(for service: KnownService) -> Text {
        var string = AttributedString(service.name)
        if let range = service.name.range(of: serviceName, options: .caseInsensitive),
           let attributedRange = Range(range, in: string) {
            string[attributedRange].font = .body.bold()
        }
        return Text(string)
    }
}

struct KnownServiceThumbnail: View {
    let service: KnownService
    var height: CGFloat = 32

    var body: some View {
        if let url = URL(string: service.favIconUrl) {
            AsyncImage(url: url,
                       content: { image in
                           image.resizable()
                               .scaledToFit()
                               .padding(4)
                               .frame(width: height, height: height)
                       },
                       placeholder: {
                           ProgressView()
                               .frame(width: height, height: height)
                       })
                       .background(.white)
                       .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            SquircleThumbnail(data: .initials(service.name.prefix(2).uppercased()),
                              tintColor: PassColor.interactionNormMajor2,
                              backgroundColor: PassColor.interactionNormMinor1,
                              height: height)
        }
    }
}

// MARK: - CreateFirstLoginView

private struct CreateFirstLoginView: View {
    @FocusState private var focusedField: Field?
    @Binding var title: String
    @Binding var email: String
    @Binding var username: String
    @Binding var password: String
    @Binding var website: String
    let service: KnownService

    enum Field: Hashable {
        case email, username, password
    }

    var body: some View {
        VStack {
            titleSection
            emailUsernamePasswordSection
            websiteSection
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, DesignConstant.onboardingPadding)
        .animation(.default, value: focusedField)
        .onAppear {
            switch service.loginType {
            case .both, .email:
                focusedField = .email
            case .username:
                focusedField = .username
            }
        }
    }
}

private extension CreateFirstLoginView {
    var titleSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Title", bundle: .module)
                    .editableSectionTitleText(for: title)

                TextField("Untitled", text: $title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(PassColor.textNorm.toColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ClearTextButton(text: $title)
        }
        .padding(DesignConstant.sectionPadding)
        .roundedEditableSection(backgroundColor: .clear)
    }

    var emailUsernamePasswordSection: some View {
        VStack(alignment: .leading, spacing: DesignConstant.sectionPadding) {
            switch service.loginType {
            case .email:
                emailTextField
                PassSectionDivider()
            case .username:
                usernameTextField
                PassSectionDivider()
            case .both:
                emailTextField
                PassSectionDivider()
                usernameTextField
                PassSectionDivider()
            }

            passwordTextField
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedEditableSection(backgroundColor: .clear)
    }

    var emailTextField: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.envelope)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Email address", bundle: .module)
                    .editableSectionTitleText(for: email)

                TrimmingTextField("Add email address", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .keyboardType(.emailAddress)
                    .submitLabel(.next)
                    .onSubmit {
                        if case .both = service.loginType {
                            focusedField = .username
                        } else {
                            focusedField = .password
                        }
                    }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ClearTextButton(text: $email)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .animation(.default, value: email.isEmpty)
    }

    var usernameTextField: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.user)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Username", bundle: .module)
                    .editableSectionTitleText(for: username)

                TrimmingTextField("Add username", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .username)
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .keyboardType(.emailAddress)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .password
                    }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ClearTextButton(text: $username)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .animation(.default, value: username.isEmpty)
    }

    var passwordTextField: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.key)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Password", bundle: .module)
                    .editableSectionTitleText(for: password)

                SensitiveTextField(text: $password,
                                   placeholder: #localized("Add password"),
                                   focusedField: $focusedField,
                                   field: .password,
                                   font: .body.monospacedFont(for: password),
                                   onSubmit: { focusedField = nil })
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .submitLabel(.next)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)

            ClearTextButton(text: $password)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .animation(.default, value: password.isEmpty)
    }

    var websiteSection: some View {
        HStack {
            ItemDetailSectionIcon(icon: IconProvider.globe)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Website", bundle: .module)
                    .editableSectionTitleText(for: website)

                TextField(text: $website) {
                    Text(verbatim: "https://")
                }
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .foregroundStyle(PassColor.textNorm.toColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ClearTextButton(text: $website)
        }
        .padding(DesignConstant.sectionPadding)
        .roundedEditableSection(backgroundColor: .clear)
    }
}
