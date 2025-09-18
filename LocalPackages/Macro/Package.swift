// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

var platforms: [SupportedPlatform] = [
    .macOS(.v12),
    .iOS(.v16),
    .tvOS(.v16),
    .watchOS(.v8)
]

let package = Package(name: "Macro",
                      platforms: platforms,
                      products: [
                        // Products define the executables and libraries a package produces, making them visible
                        // to other packages.
                        .library(name: "Macro",
                                 targets: ["Macro"])
                      ],
                      dependencies: [
                        .package(url: "https://github.com/apple/swift-syntax.git", exact: "602.0.0")
                      ],
                      targets: [
                        // Targets are the basic building blocks of a package, defining a module or a test suite.
                        // Targets can depend on other targets in this package and products from dependencies.
                        // Macro implementation that performs the source transformation of a macro.
                        .macro(name: "MacroImplementation",
                               dependencies: [
                                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
                               ],
                               path: "Sources/Implementation"),
                        
                        // Library that exposes a macro as part of its API, which is used in client programs.
                        .target(name: "Macro",
                                dependencies: [
                                    "MacroImplementation"
                                ],
                                path: "Sources/Interface"),
                        
                        // A test target used to develop the macro implementation.
                        .testTarget(name: "MacroTests",
                                    dependencies: [
                                        "MacroImplementation",
                                        "Macro",
                                        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
                                    ],
                                    path: "Tests")
                      ])
