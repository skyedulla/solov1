import SwiftUI

struct AuthFormContainer<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            content()
        }
        .frame(maxWidth: AuthTheme.formMaxWidth)
        .padding(28)
        .background(AuthTheme.cardFill, in: RoundedRectangle(cornerRadius: AuthTheme.cardCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AuthTheme.cardCorner, style: .continuous)
                .strokeBorder(Color(white: 0.2), lineWidth: 1)
        )
    }
}
