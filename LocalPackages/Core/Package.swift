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
   .enableUpcomingFeature("ForwardTrailingClosures"),
   .enableUpcomingFeature("ImplicitOpenExistentials"),
   .enableUpcomingFeature("StrictConcurrency"),
   .unsafeFlags(["-warn-concurrency", "-enable-actor-data-race-checks",
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

let package = Package(name: "Core",
                      platforms: platforms,
                      products: [
                          // Products define the executables and libraries a package produces, and make them
                          // visible to other packages.
                          .library(name: "Core",
                                   targets: ["Core"]),
                          .library(name: "CoreMocks",
                                   targets: ["CoreMocks"])
                      ],
                      dependencies: [
                          .package(url: "https://gitlab.protontech.ch/apple/shared/protoncore.git", exact: "18.0.1"),
                          .package(name: "Entities", path: "../Entities"),
                          .package(name: "DesignSystem", path: "../DesignSystem"),
                          .package(name: "Macro", path: "../Macro")
                      ],
                      targets: [
                          // Targets are the basic building blocks of a package. A target can define a module or a
                          // test suite.
                          // Targets can depend on other targets in this package, and on products in packages this
                          // package depends on.
                          .target(name: "Core",
                                  dependencies: [
                                      .product(name: "ProtonCoreDataModel", package: "protoncore"),
                                      .product(name: "ProtonCoreDoh", package: "protoncore"),
                                      .product(name: "ProtonCoreKeymaker", package: "protoncore"),
                                      .product(name: "ProtonCoreLogin", package: "protoncore"),
                                      .product(name: "ProtonCoreLoginUI", package: "protoncore"),
                                      .product(name: "ProtonCoreNetworking", package: "protoncore"),
                                      .product(name: "ProtonCoreSettings", package: "protoncore"),
                                      .product(name: "Entities", package: "Entities"),
                                      .product(name: "DesignSystem", package: "DesignSystem"),
                                      .product(name: "Macro", package: "Macro")
                                  ],
                                  resources: [
                                      .process("Resources")
                                  ],
                                  swiftSettings: swiftSettings
                                 ),
                          .target(
                              name: "CoreMocks",
                              dependencies: ["Core"]),
                          .testTarget(name: "CoreTests",
                                      dependencies: [
                                          "Core",
                                          "CoreMocks",
                                          .product(name: "ProtonCoreTestingToolkitUnitTestsCore",
                                                   package: "protoncore")

                                      ])
                      ])
