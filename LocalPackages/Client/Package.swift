// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var platforms: [SupportedPlatform] = [
    .macOS(.v12),
    .iOS(.v15),
    .tvOS(.v15),
    .watchOS(.v8)
]

let settings: [SwiftSetting] = [
  .enableExperimentalFeature("StrictConcurrency")
]

let package = Package(name: "Client",
                      platforms: platforms,
                      products: [
                          // Products define the executables and libraries a package produces, and make them
                          // visible to other packages.
                          .library(name: "Client",
                                   targets: ["Client"])
                      ],
                      dependencies: [
                          .package(url: "https://github.com/ashleymills/Reachability.swift",
                                   branch: "master"),
                          .package(name: "Core", path: "../Core"),
                          .package(name: "Entities", path: "../Entities"),
                          .package(name: "Macro", path: "../Macro"),
                          .package(url: "https://gitlab.protontech.ch/apple/shared/protoncore.git", exact: "14.0.1")
                      ],
                      targets: [
                          // Targets are the basic building blocks of a package. A target can define a module or a
                          // test suite.
                          // Targets can depend on other targets in this package, and on products in packages this
                          // package depends on.
                          .target(name: "Client",
                                  dependencies: [
                                      .product(name: "ProtonCoreDataModel", package: "protoncore"),
                                      .product(name: "ProtonCoreLogin", package: "protoncore"),
                                      .product(name: "ProtonCoreCrypto", package: "protoncore"),
                                      .product(name: "ProtonCoreNetworking", package: "protoncore"),
                                      .product(name: "ProtonCoreSettings", package: "protoncore"),
                                      .product(name: "ProtonCoreKeyManager", package: "protoncore"),
                                      .product(name: "ProtonCoreCryptoGoInterface", package: "protoncore"),
                                      .product(name: "ProtonCoreFeatureFlags", package: "protoncore"),
                                      .product(name: "ProtonCoreServices", package: "protoncore"),
                                      .product(name: "Core", package: "Core"),
                                      .product(name: "Entities", package: "Entities"),
                                      .product(name: "Reachability", package: "Reachability.swift"),
                                      .product(name: "Macro", package: "Macro")
                                  ],
                                  resources: [.process("Resources")]
//                                  ,swiftSettings: settings
                                 ),
                          .testTarget(name: "ClientTests",
                                      dependencies: ["Client"])
                      ])
