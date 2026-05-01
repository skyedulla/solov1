import SwiftUI

/// Multicolor “G” mark inspired by Google brand colors (approximation for in-app use).
struct AuthGoogleMark: View {
    var side: CGFloat

    var body: some View {
        let ring = side * 0.62
        let lineWidth = side * 0.14
        ZStack {
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            Color(red: 0.26, green: 0.52, blue: 0.96),
                            Color(red: 0.92, green: 0.25, blue: 0.21),
                            Color(red: 0.98, green: 0.75, blue: 0.18),
                            Color(red: 0.20, green: 0.66, blue: 0.33),
                            Color(red: 0.26, green: 0.52, blue: 0.96),
                        ],
                        center: .center
                    ),
                    lineWidth: lineWidth
                )
                .frame(width: ring, height: ring)

            Color(red: 0.26, green: 0.52, blue: 0.96)
                .frame(width: lineWidth * 1.25, height: lineWidth * 0.38)
                .offset(x: ring * 0.11, y: ring * 0.05)
        }
        .frame(width: side, height: side)
    }
}
