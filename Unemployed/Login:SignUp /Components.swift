import SwiftUI
import UIKit

/// Email Passowrd and Username is retrieved
struct UnderlineField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    var contentType: UITextContentType? = nil
    var keyboard: UIKeyboardType = .default

    @State private var isRevealed = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Group {
                    if isSecure && !isRevealed {
                        SecureField("", text: $text, prompt: prompt)
                    } else {
                        TextField("", text: $text, prompt: prompt)
                            .keyboardType(keyboard)
                    }
                }
                .font(Theme.semibold(20))
                .foregroundStyle(Theme.ink)
                .textContentType(contentType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                if isSecure {
                    Button { isRevealed.toggle() } label: {
                        Image(systemName: isRevealed ? "eye" : "eye.slash")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
                }
            }
            Rectangle()
                .fill(Theme.forest)
                .frame(height: 1)
        }
    }

    private var prompt: Text {
        Text(placeholder).foregroundStyle(Theme.placeholderGray)
    }
}

/// Sign Up and Log In buttons on the welcome screen
struct WelcomeButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.semibold(20))
                .foregroundStyle(Theme.onLime)
                .frame(width: 226, height: 52)
                .background(Theme.welcomeButtonFill, in: Capsule())
        }
        .buttonStyle(PressScaleStyle())
    }
}

/// Submit Buttons (confimration)
struct AuthSubmitButton: View {
    let title: String
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .font(Theme.semibold(24))
                    .opacity(isLoading ? 0 : 1)
                if isLoading { ProgressView().tint(Theme.onDark) }
            }
            .foregroundStyle(Theme.onLime)
            .frame(width: 267, height: 56)
            .background(Theme.authButtonFill, in: Capsule())
        }
        .buttonStyle(PressScaleStyle())
        .disabled(isLoading)
    }
}

/// The continue button (next lets explore)
struct CTAButton: View {
    let title: String
    var width: CGFloat = 140
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.semibold(20))
                .foregroundStyle(Theme.onLime)
                .padding(.vertical, 12)
                .frame(width: width)
                .background(Theme.ctaFill, in: Capsule())
        }
        .buttonStyle(PressScaleStyle())
    }
}

/// "Login with Facebook" / "Login with Google".
// doesnt work prolly wont for the whole session
struct SocialButton: View {
    let title: String
    let assetName: String
    let fallbackSymbol: String
    let fallbackColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.softFill)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.softBorder, lineWidth: 1))
                    .frame(height: 48)
                logo
                    .frame(width: 55, height: 55)
                    .padding(.leading, 15)
                Text(title)
                    .font(Theme.regular(18))
                    .foregroundStyle(Theme.ink)
                    .padding(.leading, 90)
            }
            .frame(height: 55)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var logo: some View {
        if UIImage(named: assetName) != nil {
            Image(assetName).resizable().scaledToFit()
        } else {
            Image(systemName: fallbackSymbol)
                .resizable()
                .scaledToFit()
                .foregroundStyle(fallbackColor)
                .padding(12)
        }
    }
}

/// No acc is associated with this email
struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 18))
            Text(message)
                .font(Theme.regular(16))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(Theme.ink)
        .padding(.horizontal, 12)
        .frame(maxWidth: 374, minHeight: 44)
        .background(Theme.softFill, in: RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.softBorder, lineWidth: 1))
    }
}

struct ErrorSlot: View {
    let message: String?

    var body: some View {
        ZStack {
            if let message {
                ErrorBanner(message: message).transition(.opacity)
            }
        }
        .frame(height: 44)
    }
}
