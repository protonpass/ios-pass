// swift-tools-version: 5.9
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

let package = Package(name: "TestingToolkit",
                      platforms: platforms,
                      products: [
                          // Products define the executables and libraries a package produces, and make them
                          // visible to other packages.
                          .library(name: "TestingToolkit",
                                   targets: ["TestingToolkit"])
                      ],
                      dependencies: [
                          // Dependencies declare other packages that this package depends on.
                          .package(name: "Entities", path: "../Entities"),
                          .package(url: "https://github.com/ProtonMail/protoncore_ios", exact: "30.0.4")
                      ],
                      targets: [
                          // Targets are the basic building blocks of a package. A target can define a module or a
                          // test suite.
                          // Targets can depend on other targets in this package, and on products in packages this
                          // package depends on.
                          .target(name: "TestingToolkit",
                                  dependencies: [
                                      .product(name: "ProtonCoreDataModel", package: "protoncore_ios"),
                                      .product(name: "ProtonCoreLogin", package: "protoncore_ios"),
                                      .product(name: "ProtonCoreNetworking", package: "protoncore_ios"),
                                      .product(name: "Entities", package: "Entities")
                                  ],
                                  swiftSettings: swiftSettings
                                 )
                      ])
