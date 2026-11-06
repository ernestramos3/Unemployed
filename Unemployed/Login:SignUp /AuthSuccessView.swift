import SwiftUI

///Succesful Login (returning user) and the second Welcome Screen (new user).
struct AuthSuccessView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let kind: AuthViewModel.WelcomeKind

    @State private var showTitle = false
    @State private var showMark = false
    @State private var draw: CGFloat = 0
    @State private var showRest = false

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width

            VStack(spacing: 0) {
                Spacer()

                Text(kind == .returningUser ? "Welcome back to" : "Welcome to")
                    .font(Theme.display(34))
                    .foregroundStyle(Theme.lime)
                    .offset(x: showTitle ? 0 : -width)

                ArrowWordmark(size: 46, draw: draw)
                    .padding(.top, 20)
                    .offset(x: showMark ? 0 : width)

                Group {
                    if kind == .newUser {
                        Text("Let\u{2019}s go through a few questions to find your matches.")
                            .font(Theme.regular(18))
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.center)
                            .frame(width: 290)
                            .padding(.top, 8)
                    }

                    CTAButton(title: kind == .returningUser ? "Let\u{2019}s Explore!" : "Next",
                              width: kind == .returningUser ? 190 : 160) {
                        auth.continueFromWelcome()
                    }
                    .padding(.top, 36)
                }
                .opacity(showRest ? 1 : 0)
                .offset(y: showRest ? 0 : 18)

                Spacer()
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.background)
        .task { await animateIn() }
    }

    private func animateIn() async {
        guard !reduceMotion else {
            showTitle = true; showMark = true; draw = 1; showRest = true
            return
        }
        let slide = Animation.spring(response: 0.6, dampingFraction: 0.82)
        withAnimation(slide) { showTitle = true }
        try? await Task.sleep(for: .milliseconds(350))
        withAnimation(slide) { showMark = true }
        try? await Task.sleep(for: .milliseconds(450))
        withAnimation(.easeInOut(duration: 0.7)) { draw = 1 }
        try? await Task.sleep(for: .milliseconds(500))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) { showRest = true }
    }
}

#Preview("Successful Login") {
    AuthSuccessView(kind: .returningUser)
        .environmentObject(AuthViewModel.preview(.welcome(.returningUser)))
}

#Preview("Successful Sign Up") {
    AuthSuccessView(kind: .newUser)
        .environmentObject(AuthViewModel.preview(.welcome(.newUser)))
}
