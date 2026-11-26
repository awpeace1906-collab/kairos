// swift-tools-version: 5.9
// Local trauma-activation engine: evaluator, profile tools (template
// expansion, validation, import save-gate) and the multi-facility profile
// library. Foundation only, no UI. Ported from the kit's reference JS
// (Resources/TraumaActivation). Profiles are data; nothing clinical lives here.
import PackageDescription

let package = Package(
    name: "TraumaCore",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [.library(name: "TraumaCore", targets: ["TraumaCore"])],
    targets: [
        .target(name: "TraumaCore"),
        .testTarget(name: "TraumaCoreTests", dependencies: ["TraumaCore"]),
    ]
)
