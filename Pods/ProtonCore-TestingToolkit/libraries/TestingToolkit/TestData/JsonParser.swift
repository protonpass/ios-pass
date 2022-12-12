//
//  JsonParser.swift
//  ProtonCore-TestingToolkig - Created on 30.09.22.
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
import ProtonCore_Log

public class JsonParser {
    public static func getValueFromJson<T>(fileName: String, bundle: Bundle = Bundle.main, key: String) -> T? {
        guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
            PMLog.debug("JsonParser: file not found")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            guard let dict = json as? [String: Any], let value = dict[key] as? T else {
                PMLog.debug("JsonParser: parse error")
                return nil
            }
            return value
        } catch let error {
            PMLog.debug("JsonParser: \(error)")
            return nil
        }
    }
}
