//
//  PMSettingsSectionViewModel.swift
//  ProtonCore-Settings - Created on 24.09.2020.
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

public typealias KeyInBundle = (key: String, bundle: Bundle)

public final class PMSettingsSectionViewModel {
    let rows: [PMCellSuplier]
    fileprivate let titleRaw: KeyInBundle?
    fileprivate let footerRaw: KeyInBundle?

    public init(title: KeyInBundle?, rows: [PMCellSuplier], footer: KeyInBundle? = nil) {
        self.titleRaw = title
        self.footerRaw = footer
        self.rows = rows
    }

    public var title: String? {
        guard let title = titleRaw else { return nil }
        return title.key.localized(in: title.bundle)
    }

    public var footer: String? {
        guard let footer = footerRaw else { return nil }
        return footer.key.localized(in: footer.bundle)
    }

    public func amending() -> PMSettingsSectionViewModelAmendor {
        PMSettingsSectionViewModelAmendor(of: self)
    }
}

public final class PMSettingsSectionViewModelAmendor {
    private var rows: [PMCellSuplier]
    private var title: KeyInBundle?
    private var footer: KeyInBundle?
    private var prepends: [PMCellSuplier] = []
    private var appends: [PMCellSuplier] = []

    // swiftlint:disable identifier_name
    internal init(of vm: PMSettingsSectionViewModel) {
        self.rows = vm.rows
        self.title = vm.titleRaw
        self.footer = vm.footerRaw
    }

    public func title(_ title: KeyInBundle?) -> PMSettingsSectionViewModelAmendor {
        self.title = title
        return self
    }

    public func footer(_ footer: KeyInBundle?) -> PMSettingsSectionViewModelAmendor {
        self.footer = footer
        return self
    }

    public func removeOriginalRows() -> PMSettingsSectionViewModelAmendor {
        rows.removeAll()
        return self
    }

    public func prepend(row: PMCellSuplier) -> PMSettingsSectionViewModelAmendor {
        prepends.append(row)
        return self
    }

    public func append(row: PMCellSuplier) -> PMSettingsSectionViewModelAmendor {
        appends.append(row)
        return self
    }

    public func amend() -> PMSettingsSectionViewModel {
        PMSettingsSectionViewModel(title: title, rows: prepends + rows + appends, footer: footer)
    }
}
