//
// UIScrollView+Extensions.swift
// Proton Pass - Created on 09/12/2024.
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

import UIKit

public extension UIScrollView {
    // periphery:ignore
    func scrollToBottom(animated: Bool = true) {
        // swiftlint:disable:next identifier_name
        let y = contentSize.height - bounds.size.height
        guard y > 0 else { return }
        setContentOffset(CGPoint(x: 0, y: contentSize.height - bounds.size.height),
                         animated: animated)
    }
}
