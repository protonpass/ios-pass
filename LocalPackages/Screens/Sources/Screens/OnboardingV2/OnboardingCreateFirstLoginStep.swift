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
import SwiftUI

struct OnboardingCreateFirstLoginStep: View {
    @StateObject private var viewModel: OnboardingCreateFirstLoginStepViewModel
    @FocusState private var focusedField: Field?
    @Binding var topBar: OnboardingV2View.TopBar

    enum Field: Hashable {
        case serviceName, title
    }

    init(topBar: Binding<OnboardingV2View.TopBar>,
         shareId: String,
         services: [KnownService],
         onCreate: @escaping (OnboardFirstLoginPayload) -> Void) {
        _topBar = topBar
        _viewModel = .init(wrappedValue: .init(shareId: shareId,
                                               services: services,
                                               onCreate: onCreate))
    }

    var body: some View {
        ZStack {
            ServiceSelectionView(serviceName: $viewModel.serviceName,
                                 suggestions: viewModel.suggestions,
                                 field: .serviceName,
                                 focusedField: $focusedField,
                                 onSelect: { service in
                                     viewModel.selectedService = service
                                     focusedField = .title
                                 })
                                 .opacity(viewModel.selectedService == nil ? 1 : 0)
            if let selectedService = viewModel.selectedService {
                view(for: selectedService)
            }
        }
        .animation(.default, value: viewModel.selectedService)
        .tint(PassColor.interactionNorm.toColor)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: viewModel.selectedService) { _ in
            if let selectedService = viewModel.selectedService {
                topBar = .createFirstLogin(selectedService,
                                           onClose: { viewModel.selectedService = nil },
                                           onSave: viewModel.save)
            } else {
                topBar = .skipButton
            }
        }
        .onAppear {
            focusedField = .serviceName
        }
    }
}

private extension OnboardingCreateFirstLoginStep {
    func view(for service: KnownService) -> some View {
        VStack {
            TextField(text: $viewModel.title) { EmptyView() }

            TextField(text: $viewModel.email) { EmptyView() }

            SecureField(text: $viewModel.password) { EmptyView() }

            Spacer()
        }
    }
}

private struct ServiceSelectionView<Field: Hashable>: View {
    @Binding var serviceName: String
    let suggestions: [KnownService]
    let field: Field
    let focusedField: FocusState<Field>.Binding
    let onSelect: (KnownService) -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("Create your first login")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(PassColor.textNorm.toColor)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)

            Text("Which service do you want to create the login for?")
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
                    .focused(focusedField, equals: field)
                    .foregroundStyle(PassColor.textNorm.toColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignConstant.sectionPadding)
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(PassColor.inputBorderNorm.toColor, lineWidth: 1))

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
            onSelect(service)
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

    var body: some View {
        if let url = URL(string: service.favIconUrl) {
            AsyncImage(url: url,
                       content: { image in
                           image.resizable()
                               .scaledToFit()
                               .padding(4)
                               .frame(width: 32, height: 32)
                       },
                       placeholder: {
                           ProgressView()
                               .frame(width: 32, height: 32)
                       })
                       .background(.white)
                       .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            SquircleThumbnail(data: .initials(service.name.prefix(2).uppercased()),
                              tintColor: PassColor.interactionNormMajor2,
                              backgroundColor: PassColor.interactionNormMinor1,
                              height: 32)
        }
    }
}
