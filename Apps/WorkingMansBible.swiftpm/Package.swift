// swift-tools-version: 5.9

// The Working Man's Bible app for iPhone and iPad (also runs on Apple silicon Macs).
// An app package: open this folder in Xcode or Swift Playgrounds and press Run.
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "WorkingMansBible",
    platforms: [.iOS("17.0")],
    products: [
        .iOSApplication(
            name: "WorkingMansBible",
            targets: ["AppModule"],
            bundleIdentifier: "io.github.mccormick6545.WorkingMansBible",
            displayVersion: "0.1",
            bundleVersion: "1",
            accentColor: .presetColor(.orange),
            supportedDeviceFamilies: [.pad, .phone],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    dependencies: [
        .package(path: "../../Packages/Shared/WorkingMansPartsCatalogUI")
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            dependencies: [.product(name: "WorkingMansPartsCatalogUI", package: "WorkingMansPartsCatalogUI")],
            path: "."
        )
    ]
)
