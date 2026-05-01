import SwiftUI

struct AuthPrimaryButton: View {
    let title: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .background(AuthTheme.primaryButtonFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .foregroundStyle(AuthTheme.primaryButtonText)
    }
}
