//
//
// CheckCameraPermission.swift
// Proton Pass - Created on 10/07/2023.
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

import AVFoundation
import Combine

public protocol CheckCameraPermissionUseCase: Sendable {
    func execute(for mediaType: AVMediaType) async -> Bool
}

public extension CheckCameraPermissionUseCase {
    func callAsFunction(for mediaType: AVMediaType = .video) async -> Bool {
        await execute(for: mediaType)
    }
}

public final class CheckCameraPermission: CheckCameraPermissionUseCase {
    public init() {}

    public func execute(for mediaType: AVMediaType = .video) async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: mediaType)

        let isAuthorized = if status == .notDetermined {
            // If the system hasn't determined the user's authorization status,
            // explicitly prompt them for approval.
            await AVCaptureDevice.requestAccess(for: mediaType)
        } else {
            // Determine if the user previously authorized camera access.
            status == .authorized
        }

        return isAuthorized
    }
}
