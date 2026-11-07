// swift-tools-version:5.10
import PackageDescription

let swiftSettings: [SwiftSetting] = [.enableUpcomingFeature("BareSlashRegexLiterals")]

let package = Package(
    name: "MDReader",
    platforms: [.macOS(.v14)],
    dependencies: [
        // Kokoro text-to-speech on MLX. Build with Scripts/build.sh:
        // xcodebuild is required because plain `swift build` doesn't compile MLX's Metal shaders.
        .package(url: "https://github.com/Blaizzy/mlx-audio-swift.git", exact: "0.1.8"),
        .package(url: "https://github.com/huggingface/swift-huggingface.git", from: "0.8.1"),
        .package(url: "https://github.com/sparkle-project/Sparkle.git", exact: "2.10.1"),
    ],
    targets: [
        .target(
            name: "MDReaderCore",
            dependencies: [
                .product(name: "MLXAudioTTS", package: "mlx-audio-swift"),
                .product(name: "MLXAudioCore", package: "mlx-audio-swift"),
                .product(name: "HuggingFace", package: "swift-huggingface"),
            ],
            swiftSettings: swiftSettings),
        .executableTarget(
            name: "MDReader",
            dependencies: ["MDReaderCore", .product(name: "Sparkle", package: "Sparkle")],
            swiftSettings: swiftSettings,
            // Sparkle.framework is embedded in Contents/Frameworks by Scripts/build.sh.
            linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])]),
        .testTarget(name: "MDReaderCoreTests", dependencies: ["MDReaderCore"], swiftSettings: swiftSettings),
    ]
)
