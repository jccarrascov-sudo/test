// swift-tools-version: 5.9

// Proyecto para Swift Playgrounds (iPad) y Xcode (Mac).
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "MisNotas",
    platforms: [
        .iOS("26.0")
    ],
    products: [
        .iOSApplication(
            name: "MisNotas",
            targets: ["AppModule"],
            bundleIdentifier: "pe.misnotas.app",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .pencil),
            accentColor: .presetColor(.indigo),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "."
        )
    ]
)
