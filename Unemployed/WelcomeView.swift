import SwiftUI

/// Welcome Screen (app mark + wordmark + Signup / Login)
struct WelcomeView: View {
    let onSignUp: () -> Void
    let onLogin: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            AppMark(size: 190)

            ArrowWordmark(size: 44)
                .padding(.top, 40)

            Text("not for long.")
                .font(Theme.semibold(18))
                .foregroundStyle(Theme.skipGray)
                .padding(.top, 2)

            Spacer()

            VStack(spacing: 14) {
                WelcomeButton(title: "Signup", action: onSignUp)
                WelcomeButton(title: "Login", action: onLogin)
            }
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview("Welcome") {
    WelcomeView(onSignUp: {}, onLogin: {})
}
