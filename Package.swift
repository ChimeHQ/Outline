// swift-tools-version: 5.8

import PackageDescription

let settings: [SwiftSetting] = [
	.enableExperimentalFeature("StrictConcurrency")
]

let package = Package(
	name: "Outline",
	platforms: [.macOS(.v11)],
	products: [
		.library(name: "Outline", targets: ["Outline"]),
	],
	targets: [
		.target(
			name: "Outline",
			swiftSettings: settings
		),
		.testTarget(
			name: "OutlineTests",
			dependencies: ["Outline"],
			swiftSettings: settings
		),
	]
)
