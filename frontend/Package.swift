// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SoloAuthSmoke",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "solo-auth-smoke", targets: ["SoloAuthSmoke"]),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "SoloAuthSmoke",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
            ],
            path: "lib",
            sources: [
                "core/config/AppConfiguration.swift",
                "features/auth/models/AuthModel.swift",
                "features/auth/supabase/SupabaseClientProvider.swift",
                "features/auth/controllers/AuthController.swift",
                "smoke/SoloAuthSmoke.swift",
            ]
        ),
    ]
)
