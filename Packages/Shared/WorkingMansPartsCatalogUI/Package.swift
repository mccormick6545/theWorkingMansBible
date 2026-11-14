// swift-tools-version: 5.9
import PackageDescription

// SwiftUI screens for the offline parts catalog: search, categories, details, sources and favorites.
// Shared by the home and vehicle sides. iOS 17 / macOS 14 for Observation and ContentUnavailableView.
let package = Package(
    name: "WorkingMansPartsCatalogUI",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "WorkingMansPartsCatalogUI", targets: ["WorkingMansPartsCatalogUI"])],
    dependencies: [.package(path: "../WorkingMansPartsCatalog")],
    targets: [
        .target(name: "WorkingMansPartsCatalogUI", dependencies: ["WorkingMansPartsCatalog"]),
        .testTarget(name: "WorkingMansPartsCatalogUITests", dependencies: ["WorkingMansPartsCatalogUI"])
    ]
)
