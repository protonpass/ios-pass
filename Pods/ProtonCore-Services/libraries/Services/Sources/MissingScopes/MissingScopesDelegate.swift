//
//  MissingScopesDelegate.swift
//  ProtonCore-Services - Created on 26.04.23.
//
//  Copyright (c) 2023 Proton Technologies AG
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import ProtonCore_Networking

public protocol MissingScopesDelegate: AnyObject {
    func getAuthInfo(username: String, completion: @escaping (Result<AuthInfoResponse, AuthErrors>) -> Void)
    func onMissingScopesHandling(authInfo: AuthInfoResponse, username: String, responseHandlerData: PMResponseHandlerData, completion: @escaping (MissingScopesFinishReason) -> Void)
    func showAlert(title: String, message: String?)
}

public enum MissingScopesFinishReason {
    case verified(SRPClientInfo)
    case closed
    case closedWithError(code: Int, description: String)
}
