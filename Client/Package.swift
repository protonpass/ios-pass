// swift-tools-version:5.6
//
// Package.swift
// Proton Key - Created on 15/06/2022.
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

import PackageDescription

let package = Package(
    name: "ProtonKeyClient",
    platforms: [
        .macOS(.v11), .iOS(.v14),
    ],
    products: [
        .library(name: "Client", targets: ["Client"]),
    ],
    targets: [
        .target(
            name: "Client",
            path: "Sources")
    ]
)
