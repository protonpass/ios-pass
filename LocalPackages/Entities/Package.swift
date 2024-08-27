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

let package = Package(name: "Entities",
                      defaultLocalization: "en",
                      platforms: platforms,
                      products: [
                          // Products define the executables and libraries a package produces, and make them
                          // visible to other packages.
                          .library(name: "Entities",
                                   targets: ["Entities"]),
                          .library(name: "EntitiesMocks",
                                   targets: ["EntitiesMocks"])
                      ],
                      dependencies: [
                          // Dependencies declare other packages that this package depends on.
                          // .package(url: /* package url */, from: "1.0.0"),
                        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.28.0")
                      ],
                      targets: [
                          // Targets are the basic building blocks of a package. A target can define a module or a
                          // test suite.
                          // Targets can depend on other targets in this package, and on products in packages this
                          // package depends on.
                          .target(name: "Entities",
                                  dependencies: [
                                    .product(name: "SwiftProtobuf", package: "swift-protobuf")
                                  ],
                                  swiftSettings: swiftSettings),
                          .target(
                              name: "EntitiesMocks",
                              dependencies: ["Entities"]),
                          .testTarget(name: "EntitiesTests",
                                      dependencies: ["Entities"])
                      ])
