// swift-tools-version: 6.0
import PackageDescription

let package = Package(
	name: "Core",
	platforms: [.iOS(.v17), .macOS(.v15)],
	products: [
		.library(name: "Core", targets: ["Core"]),
	],
	dependencies: [
		.package(url: "https://github.com/groue/GRDB.swift.git", .upToNextMajor(from: "7.0.0-beta.6")),
		.package(url: "https://github.com/CrunchyBagel/OutcastID3.git", .upToNextMajor(from: "0.7.1")),
		.package(url: "https://github.com/nmdias/FeedKit.git", .upToNextMajor(from: "9.1.2")),
	],
	targets: [
		.target(
			name: "Core",
			dependencies: [
				.product(name: "GRDB", package: "grdb.swift"),
				"FeedKit",
				"OutcastID3",
			],
			resources: [.copy("../../../Submodules/Readability/Readability.js")]
		),
		.testTarget(
			name: "CoreTests",
			dependencies: ["Core"],
			resources: [.process("Fixtures")]
		),
	]
)
