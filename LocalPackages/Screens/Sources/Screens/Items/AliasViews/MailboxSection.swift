//
// MailboxSection.swift
// Proton Pass - Created on 02/08/2024.
// Copyright (c) 2024 Proton Technologies AG
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

import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
import SwiftUI

public struct MailboxSection: View {
    let mailboxSelection: AliasLinkedMailboxSelection
    let mode: Mode

    public init(mailboxSelection: AliasLinkedMailboxSelection, mode: Mode) {
        self.mailboxSelection = mailboxSelection
        self.mode = mode
    }

    public enum Mode: Sendable {
        case create, edit

        public var title: String {
            switch self {
            case .create:
                #localized("Forward to")
            case .edit:
                #localized("Forwarding to")
            }
        }
    }

    public var body: some View {
        HStack {
            ItemDetailSectionIcon(icon: IconProvider.forward)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(mode.title)
                    .sectionTitleText()
                Text(mailboxSelection.selectedMailboxesString)
                    .sectionContentText()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ItemDetailSectionIcon(icon: IconProvider.chevronDown)
        }
        .animation(.default, value: mailboxSelection)
        .padding(DesignConstant.sectionPadding)
        .roundedEditableSection()
        .contentShape(.rect)
    }
}
