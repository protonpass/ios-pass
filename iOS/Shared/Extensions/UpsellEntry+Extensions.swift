//
// UpsellEntry+Extensions.swift
// Proton Pass - Created on 17/06/2024.
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
import Foundation
import Macro
import ProtonCoreUIFoundations
import Screens

extension UpsellEntry {
    var description: String {
        switch self {
        case .generic, .missing2fa, .secureLink, .sentinel:
            #localized("Unlock advanced security features and detailed logs to safeguard your online presence.")
        case .darkWebMonitorNoBreach:
            #localized("Dark Web Monitoring is available with a paid plan. Upgrade for immediate access.")
        case .darkWebMonitorBreach:
            // swiftlint:disable:next line_length
            #localized("Your personal data was leaked by an online service in a data breach. Upgrade to view full details and get recommended actions.")
        case .aliasManagement:
            #localized("Advanced alias management is available with Pass Unlimited. Upgrade for immediate access.")
        }
    }

    var defaultConfiguration: UpsellingViewConfiguration {
        UpsellingViewConfiguration(icon: PassIcon.passPlus,
                                   title: #localized("Stay safer online"),
                                   description: description,
                                   upsellElements: upsellElements,
                                   ctaTitle: #localized("Get Pass Plus"))
    }

    var upsellElements: [UpsellElement] {
        var upsellElements = [UpsellElement]()
        switch self {
        case .secureLink:
            upsellElements.append(UpsellElement(icon: IconProvider.link,
                                                title: #localized("Secure links"),
                                                color: PassColor.interactionNormMajor2))
        case .darkWebMonitorNoBreach:
            upsellElements.append(UpsellElement(icon: PassIcon.shield2,
                                                title: #localized("Dark Web Monitoring"),
                                                color: PassColor.interactionNormMajor2))
        case .aliasManagement:
            upsellElements.append(UpsellElement(icon: IconProvider.mailbox,
                                                title: #localized("Advanced alias management"),
                                                color: PassColor.interactionNormMajor2))
        default:
            break
        }
        upsellElements.append(contentsOf: [UpsellElement].default)
        return upsellElements
    }
}
