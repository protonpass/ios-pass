//
// EditDomainMatchingView.swift
// Proton Pass - Created on 22/06/2026.
// Copyright (c) 2026 Proton Technologies AG
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

import Core
import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
import SwiftUI

private enum DomainMatchingType: Int, Hashable {
    case basic = 0
    case advanced = 1

    var title: String {
        switch self {
        case .basic: #localized("Basic", bundle: .module)
        case .advanced: #localized("Advanced", bundle: .module)
        }
    }
}

public struct EditDomainMatchingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: DomainMatchingType
    @State private var selectedMode: AutofillUrlMode
    private let url: IdentifiableObject<AutofillUrl>
    private let itemContentType: ItemContentType = .login
    private let onSave: (AutofillUrlMode) -> Void

    public init(url: IdentifiableObject<AutofillUrl>,
                onSave: @escaping (AutofillUrlMode) -> Void) {
        self.url = url
        _selectedType = .init(initialValue: url.value.mode.isBasic ? .basic : .advanced)
        _selectedMode = .init(initialValue: url.value.mode)
        self.onSave = onSave
    }

    public var body: some View {
        NavigationStack {
            mainContent
                .background(PassColor.backgroundNorm)
                .navigationTitle(Text("URL matching", bundle: .module))
                .tint(itemContentType.normMajor1Color)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        CircleButton(icon: IconProvider.cross,
                                     iconColor: itemContentType.normMajor2Color,
                                     backgroundColor: itemContentType.normMinor1Color,
                                     accessibilityLabel: "Close",
                                     action: dismiss.callAsFunction)
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        CapsuleTextButton(title: #localized("Save"),
                                          titleColor: PassColor.textInvert,
                                          backgroundColor: itemContentType.normMajor1Color,
                                          action: { onSave(selectedMode); dismiss() })
                    }
                }
        }
    }
}

private extension EditDomainMatchingView {
    var mainContent: some View {
        ScrollView {
            VStack(spacing: DesignConstant.sectionPadding) {
                descriptionText

                EnumSegmentedPicker(selection: $selectedType,
                                    options: [
                                        DomainMatchingType.basic.title,
                                        DomainMatchingType.advanced.title
                                    ],
                                    mainColor: itemContentType.normMajor1Color,
                                    backgroundColor: itemContentType.normMinor1Color)

                switch selectedType {
                case .basic:
                    basicContent

                case .advanced:
                    advancedContent
                }

                Spacer()
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.default, value: selectedType)
            .animation(.default, value: selectedMode)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    @ViewBuilder
    var descriptionText: some View {
        let urlString = url.value.url
        let rawDescription =
            #localized("Adjust autofill behaviors to change where logins are suggested and filled for %@.",
                       urlString)
        // Heuristic to detect if the URL is valid or not in order to highlight it
        // Because for example if the URL is simply "a", we would end up highlighting
        // the first "a" character.
        if urlString.contains("."), urlString.count > 5 {
            let attributedString: AttributedString = {
                var attributedString = AttributedString(rawDescription)
                attributedString.foregroundColor = PassColor.textWeak
                if let range = attributedString.range(of: urlString) {
                    attributedString[range].foregroundColor = PassColor.textNorm
                }
                return attributedString
            }()
            Text(attributedString)
        } else {
            Text(verbatim: rawDescription)
                .foregroundStyle(PassColor.textWeak)
        }
    }

    var basicContent: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            row(for: .default)
            row(for: .never)
            row(for: .exact)
            // swiftlint:disable:next line_length
            unavailableText("Exact subdomain rule is not available on iOS due to limitations in the operating system APIs.")
        }
    }

    var advancedContent: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            row(for: .startWith)
            row(for: .regularExpression)
            row(for: .pattern)
            row(for: .exactPath)
            unavailableText("Advanced rules are not available on iOS due to limitations in the operating system APIs.")
        }
    }

    @ViewBuilder
    func row(for mode: AutofillUrlMode) -> some View {
        let isSelected = mode == selectedMode
        Button {
            selectedMode = mode
        } label: {
            HStack {
                Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24)
                    .foregroundStyle(isSelected ? itemContentType.normMajor2Color : PassColor.textWeak)

                ViewThatFits {
                    HStack {
                        text(for: mode)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading) {
                        text(for: mode)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .contentShape(.rect)
        }
        .disabled(!mode.isSupported)
        .opacity(mode.isSupported ? 1.0 : 0.5)
    }

    @ViewBuilder
    func text(for mode: AutofillUrlMode) -> some View {
        Text(mode.title)
            .foregroundStyle(PassColor.textNorm)

        if mode == .default {
            Text("DEFAULT", bundle: .module)
                .font(.caption)
                .foregroundStyle(itemContentType.normMajor2Color)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(itemContentType.normMinor1Color)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    func unavailableText(_ text: LocalizedStringKey) -> some View {
        Text(text, bundle: .module)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(PassColor.textNorm)
            .padding()
            .background(PassColor.inputBackgroundNorm)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private extension AutofillUrlMode {
    var isBasic: Bool {
        switch self {
        case .default, .exact, .never: true
        default: false
        }
    }

    var isSupported: Bool {
        switch self {
        case .default, .never: true
        default: false
        }
    }
}
