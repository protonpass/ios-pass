// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var platforms: [SupportedPlatform] = [
    .macOS(.v12),
    .iOS(.v16),
    .tvOS(.v16),
    .watchOS(.v8)
]

let package = Package(name: "DesignSystem",
                      defaultLocalization: "en",
                      platforms: platforms,
                      products: [
                          // Products define the executables and libraries a package produces, and make them
                          // visible to other packages.
                          .library(name: "DesignSystem",
                                   targets: ["DesignSystem"])
                      ],
                      dependencies: [
                          // Dependencies declare other packages that this package depends on.
                        .package(url: "https://github.com/ProtonMail/protoncore_ios", exact: "32.7.1"),
                        .package(url: "https://github.com/jdg/MBProgressHUD", exact: "1.2.0"),
                        .package(name: "Macro", path: "../Macro")
                      ],
                      targets: [
                          // Targets are the basic building blocks of a package. A target can define a module or a
                          // test suite.
                          // Targets can depend on other targets in this package, and on products in packages this
                          // package depends on.
                          .target(name: "DesignSystem",
                                  dependencies: [
                                    .product(name: "ProtonCoreLoginUI", package: "protoncore_ios"),
                                    .product(name: "MBProgressHUD", package: "MBProgressHUD"),
                                    .product(name: "Macro", package: "Macro")
                                  ],
                                  resources: [.process("Resources")]),
                          .testTarget(name: "DesignSystemTests",
                                      dependencies: ["DesignSystem"])
                      ],
                      swiftLanguageModes: [.version("6")]
)
