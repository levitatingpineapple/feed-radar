// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "UI",
    platforms: [.iOS(.v17)],
    products: [.library(name: "UI", targets: ["UI"])],
    dependencies: [
        .package(path: "../Core"),
        .package(url: "https://github.com/groue/GRDBQuery.git", .upToNextMajor(from: "0.10.1")),
    ],
    targets: [
		.target(
			name: "UI",
			dependencies: ["Core", "GRDBQuery"],
			resources: [.process("Resources")]
		),
    ]
)
