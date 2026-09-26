//
// UpsellingViewConfiguration+Extensions.swift
// Proton Pass - Created on 27/07/2026.
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

import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations

public extension UpsellingViewConfiguration {
    static var `default`: UpsellingViewConfiguration {
        UpsellingViewConfiguration(icon: PassIcon.passPlus,
                                   title: #localized("Stay safer online", bundle: .module),
                                   description: UpsellEntry.generic.description,
                                   upsellElements: .default,
                                   ctaTitle: #localized("Get Pass Plus", bundle: .module))
    }

    static var essentials: UpsellingViewConfiguration {
        UpsellingViewConfiguration(icon: PassIcon.passPlus,
                                   title: #localized("Stay safer online", bundle: .module),
                                   description: UpsellEntry.generic.description,
                                   upsellElements: .essentials,
                                   ctaTitle: #localized("Get Pass Business", bundle: .module))
    }
}

extension [UpsellElement] {
    static var `default`: Self {
        [
            UpsellElement(icon: IconProvider.user,
                          title: #localized("Proton Sentinel", bundle: .module),
                          color: PassColor.interactionNormMajor2),
            UpsellElement(icon: IconProvider.lock,
                          title: #localized("Integrated 2FA authenticator", bundle: .module),
                          color: PassColor.interactionNormMajor2),
            UpsellElement(icon: IconProvider.alias,
                          title: #localized("Unlimited hide-my-email aliases", bundle: .module),
                          color: PassColor.interactionNormMajor2),
            UpsellElement(icon: IconProvider.usersPlus,
                          title: #localized("Vault sharing (up to 10 people)", bundle: .module),
                          color: PassColor.interactionNormMajor2)
        ]
    }

    static var essentials: Self {
        [
            UpsellElement(icon: IconProvider.user,
                          title: #localized("Proton Sentinel", bundle: .module),
                          color: PassColor.interactionNormMajor2),
            UpsellElement(icon: IconProvider.lock,
                          title: #localized("Require 2FA for organization", bundle: .module),
                          color: PassColor.interactionNormMajor2),
            UpsellElement(icon: IconProvider.checkmark,
                          title: #localized("SSO integration (coming soon)", bundle: .module),
                          color: PassColor.interactionNormMajor2)
        ]
    }
}
