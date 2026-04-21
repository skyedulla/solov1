// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SoloAuthSmoke",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "solo-auth-smoke", targets: ["SoloAuthSmoke"]),
        .library(name: "SoloLib", targets: ["SoloLib"]),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "SoloLib",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
            ],
            path: "lib",
            exclude: ["smoke"],
            sources: [
                "core/config/AppConfiguration.swift",
                "core/constants/sort_by_constants.swift",
                "features/auth/models/AuthModel.swift",
                "features/auth/supabase/SupabaseClientProvider.swift",
                "features/auth/controllers/AuthController.swift",
                "features/ideas/controllers/IdeaController.swift",
                "features/ideas/controllers/IdeaSearchController.swift",
                "features/ideas/data_source/IdeasRemoteDataSource.swift",
                "features/ideas/models/IdeaFilterModel.swift",
                "features/ideas/models/IdeaModel.swift",
            ]
        ),
        .executableTarget(
            name: "SoloAuthSmoke",
            dependencies: ["SoloLib"],
            path: "lib/smoke",
            sources: ["SoloAuthSmoke.swift"]
        ),
        .testTarget(
            name: "SoloLibTests",
            dependencies: ["SoloLib"],
            path: "Tests/SoloLibTests"
        ),
    ]
)
