// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "nexus_shell",
    platforms: [
        .iOS(.v17)
    ],
    dependencies: [
        .package(path: "/tmp/NMSSH")
    ],
    targets: [
        .executableTarget(
            name: "nexus_shell",
            dependencies: [
                .product(name: "NMSSH", package: "NMSSH")
            ],
            path: ".",
            exclude: [
                "plan",
                "Podfile",
                "project.yml",
                "Resources",
                ".claude",
                ".git",
                ".gitignore",
                "nexus_shell.xcodeproj",
                "Package.swift"
            ],
            sources: [
                "App",
                "Models",
                "ViewModels",
                "Views",
                "Services",
                "Utilities"
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        )
    ]
)
