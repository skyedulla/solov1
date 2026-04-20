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
                "core/constants/sort_by_constants.swift",
                "features/auth/models/AuthModel.swift",
                "features/auth/supabase/SupabaseClientProvider.swift",
                "features/auth/controllers/AuthController.swift",
                "features/ideas/controllers/IdeaController.swift",
                "features/ideas/controllers/IdeaSearchController.swift",
                "features/ideas/data_source/IdeasRemoteDataSource.swift",
                "features/ideas/models/IdeaFilterModel.swift",
                "features/ideas/models/IdeaModel.swift",
                "smoke/SoloAuthSmoke.swift",
            ]
        ),
    ]
)
