// swift-tools-version: 5.9
// Shared extubation decision engine (cv-extubation-logic). Foundation only, no
// UI. Started from AnesCalc's port; Kairos hosts it so both apps can depend on
// one tested copy. Tests read the kit files from the repo's
// Resources/Extubation/ folder rather than keeping another copy of the JSON.
import PackageDescription

let package = Package(
    name: "ExtubationEngine",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [.library(name: "ExtubationEngine", targets: ["ExtubationEngine"])],
    targets: [
        .target(name: "ExtubationEngine"),
        .testTarget(name: "ExtubationEngineTests", dependencies: ["ExtubationEngine"]),
    ]
)
