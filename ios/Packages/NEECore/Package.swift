// swift-tools-version: 5.9
// NEE (norepinephrine equivalents) engine. Foundation only, no UI, so AnesCalc
// can adopt it later with its own skin. Tests read the kit from the repo's
// Resources/NEE/ folder rather than keeping another copy of the JSON.
import PackageDescription

let package = Package(
    name: "NEECore",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [.library(name: "NEECore", targets: ["NEECore"])],
    targets: [
        .target(name: "NEECore"),
        .testTarget(name: "NEECoreTests", dependencies: ["NEECore"]),
    ]
)
