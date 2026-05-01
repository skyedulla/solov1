import SwiftUI

struct AuthLabeledTextField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AuthTheme.labelText)
            Group {
                if isSecure {
                    SecureField("", text: $text)
                } else {
                    TextField("", text: $text)
                }
            }
            .textFieldStyle(.plain)
            .padding(10)
            .background(AuthTheme.fieldFill, in: RoundedRectangle(cornerRadius: AuthTheme.fieldCorner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AuthTheme.fieldCorner, style: .continuous)
                    .strokeBorder(AuthTheme.fieldBorder, lineWidth: 1)
            )
            .foregroundStyle(AuthTheme.labelText)
        }
    }
}
