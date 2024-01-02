//
// InviteSuggestionsSection.swift
// Proton Pass - Created on 15/12/2023.
// Copyright (c) 2023 Proton Technologies AG
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
import Entities
import Macro
import SwiftUI

public struct InviteSuggestionsSection: View {
    @State private var selectedIndex = 0
    @Binding private var selectedEmails: [String]
    let recommendations: InviteRecommendations

    public init(selectedEmails: Binding<[String]>, recommendations: InviteRecommendations) {
        _selectedEmails = selectedEmails
        self.recommendations = recommendations
    }

    public var body: some View {
        VStack {
            Text("Suggestions")
                .foregroundStyle(PassColor.textWeak.toColor)
                .font(.body.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)

            if let planName = recommendations.groupDisplayName ?? recommendations.planInternalName {
                SegmentedPicker(selectedIndex: $selectedIndex,
                                options: [#localized("Recents"), planName])
            }

            emailList(selectedIndex == 0 ?
                recommendations.recommendedEmails : recommendations.planRecommendedEmails)
        }
    }
}

private extension InviteSuggestionsSection {
    func emailList(_ emails: [String]) -> some View {
        ForEach(emails, id: \.self) { email in
            SuggestedEmailView(selectedEmails: $selectedEmails, email: email)
        }
    }
}
