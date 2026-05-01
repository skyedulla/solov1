import SwiftUI

struct AuthModeSwitchRow: View {
    let lead: String
    let actionTitle: String
    var action: () -> Void = {}

    var body: some View {
        HStack(spacing: 4) {
            Text(lead)
                .foregroundStyle(AuthTheme.secondaryText)
            Button(action: action) {
                Text(actionTitle)
                    .foregroundStyle(AuthTheme.linkText)
            }
            .buttonStyle(.plain)
        }
        .font(.subheadline)
    }
}
