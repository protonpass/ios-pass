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

let package = Package(name: "UseCases",
                      platforms: platforms,
                      products: [
                          // Products define the executables and libraries a package produces, and make them
                          // visible to other packages.
                          .library(name: "UseCases",
                                   targets: ["UseCases"]),
                          .library(name: "UseCasesMocks",
                                   targets: ["UseCasesMocks"])
                      ],
                      dependencies: [
                          // Dependencies declare other packages that this package depends on.
                          .package(name: "Entities", path: "../Entities"),
                          .package(name: "Core", path: "../Core"),
                          .package(name: "Client", path: "../Client"),
                          .package(name: "PassRustCore", path: "../PassRustCore"),
                          .package(url: "https://github.com/getsentry/sentry-cocoa.git", exact: "8.29.0"),
                          .package(url: "https://github.com/ProtonMail/protoncore_ios", exact: "25.3.4")
                      ],
                      targets: [
                          // Targets are the basic building blocks of a package. A target can define a module or a
                          // test suite.
                          // Targets can depend on other targets in this package, and on products in packages this
                          // package depends on.
                          .target(name: "UseCases",
                                  dependencies: [
                                      .product(name: "Entities", package: "Entities"),
                                      .product(name: "Client", package: "Client"),
                                      .product(name: "Core", package: "Core"),
                                      .product(name: "PassRustCore", package: "PassRustCore"),
                                      .product(name: "Sentry", package: "sentry-cocoa"),
                                      .product(name: "ProtonCoreFeatureFlags", package: "protoncore_ios"),
                                      .product(name: "ProtonCoreTelemetry", package: "protoncore_ios")
                                  ],
                                  resources: [],
                                  swiftSettings: swiftSettings
                                 ),
                          .target(
                              name: "UseCasesMocks",
                              dependencies: ["UseCases"]),
                          .testTarget(name: "UseCasesTests",
                                      dependencies: ["UseCases",
                                                     "UseCasesMocks",
                                                     .product(name: "ClientMocks", package: "Client"),
                                                     .product(name: "CoreMocks", package: "Core"),
                                                     .product(name: "EntitiesMocks", package: "Entities"),
                                                     .product(name: "ProtonCoreForceUpgrade", package: "protoncore_ios")
                                                    ],
                                      path: "Tests")
                      ])
