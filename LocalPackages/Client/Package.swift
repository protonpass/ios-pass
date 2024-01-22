// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var platforms: [SupportedPlatform] = [
    .macOS(.v12),
    .iOS(.v16),
    .tvOS(.v16),
    .watchOS(.v8)
]

let swiftSettings: [SwiftSetting] = [
   .enableUpcomingFeature("BareSlashRegexLiterals"),
   .enableUpcomingFeature("ConciseMagicFile"),
   .enableUpcomingFeature("ExistentialAny"),
//   .enableUpcomingFeature("ForwardTrailingClosures"),
   .enableUpcomingFeature("ImplicitOpenExistentials"),
   .enableUpcomingFeature("StrictConcurrency"),
   .unsafeFlags(["-warn-concurrency", 
                 "-enable-actor-data-race-checks",
                 "-driver-time-compilation",
                 "-Xfrontend",
                 "-debug-time-function-bodies",
                 "-Xfrontend",
                 "-debug-time-expression-type-checking",
                 "-Xfrontend",
                 "-warn-long-function-bodies=100",
                 "-Xfrontend",
                 "-warn-long-expression-type-checking=100"
                ])
]

let package = Package(name: "Client",
                      platforms: platforms,
                      products: [
                          // Products define the executables and libraries a package produces, and make them
                          // visible to other packages.
                          .library(name: "Client",
                                   targets: ["Client"]),
                          .library(name: "ClientMocks",
                                   targets: ["ClientMocks"])
                      ],
                      dependencies: [
                          .package(name: "Core", path: "../Core"),
                          .package(name: "Entities", path: "../Entities"),
                          .package(name: "Macro", path: "../Macro"),
                          .package(url: "https://gitlab.protontech.ch/apple/shared/protoncore.git", exact: "18.0.1")
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
                                      .product(name: "Macro", package: "Macro")
                                  ],
                                  resources: [.process("Resources")],
                                  swiftSettings: swiftSettings
                                 ),
                          .target(
                              name: "ClientMocks",
                              dependencies: ["Client"]),
                          .testTarget(name: "ClientTests",
                                      dependencies: ["Client",
                                                     .product(name: "CoreMocks", package: "Core"),
                                                     .product(name: "EntitiesMocks", package: "Entities"),
                                                     "ClientMocks"
                                                    ])
                      ])
