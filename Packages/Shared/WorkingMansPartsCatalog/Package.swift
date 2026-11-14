// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "WorkingMansPartsCatalog",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [.library(name: "WorkingMansPartsCatalog", targets: ["WorkingMansPartsCatalog"])],
    targets: [
        .target(name: "WorkingMansPartsCatalog"),
        .testTarget(name: "WorkingMansPartsCatalogTests", dependencies: ["WorkingMansPartsCatalog"])
    ]
)
