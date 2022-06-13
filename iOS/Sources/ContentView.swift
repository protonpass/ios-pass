//
// ContentView.swift
// Proton Key - Created on 03/06/2022.
// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Key.
//
// Proton Key is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Key is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Key. If not, see https://www.gnu.org/licenses/.

import SwiftUI

struct ContentView: View {
    var body: some View {
        let host = Bundle.main.infoDictionary?["DEFAULT_API_HOST"] as? String ?? "null"
        let signUp = Bundle.main.infoDictionary?["DEFAULT_SIGNUP_DOMAIN"] as? String ?? "null"
        VStack {
            #if PROD
            Text("Prod")
            #elseif BLACK
            Text("Black")
            #endif
            Text("Host domain: " + host)
            Text("Sign up domain: " + signUp)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
