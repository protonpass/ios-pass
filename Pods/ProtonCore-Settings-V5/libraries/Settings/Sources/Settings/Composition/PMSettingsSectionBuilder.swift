//
//  PMSettingsSectionBuilder.swift
//  ProtonCore-Settings - Created on 22.10.2020.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

public final class PMSettingsSectionBuilder {
    let bundle: Bundle
    private var title: String?
    private var footer: String?
    private var rows: [PMCellSuplier] = []

    public init(bundle: Bundle) {
        self.bundle = bundle
    }

    public func title(_ title: String?) -> PMSettingsSectionBuilder {
        self.title = title
        return self
    }

    public func footer(_ footer: String?) -> PMSettingsSectionBuilder {
        self.footer = footer
        return self
    }

    public func appendRow(_ row: PMCellSuplier) -> PMSettingsSectionBuilder {
        rows.append(row)
        return self
    }

    public func appendRowIfAvailable(_ row: PMCellSuplier?) -> PMSettingsSectionBuilder {
        guard let row = row else { return self }
        rows.append(row)
        return self
    }

    public func build() -> PMSettingsSectionViewModel {
        PMSettingsSectionViewModel(
            title: keyInBundle(for: title),
            rows: rows,
            footer: keyInBundle(for: footer))
    }

    private func keyInBundle(for key: String?) -> KeyInBundle? {
        var keyInBundle: KeyInBundle?
        if let key = key {
            keyInBundle = (key, bundle)
        }
        return keyInBundle
    }
}
