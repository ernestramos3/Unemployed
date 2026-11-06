import SwiftUI

/// Picks which screen to show based on whether someone is signed in
struct RootView: View {
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        Group {
            switch auth.state {
            case .loading:
                ProgressView()
                    .tint(Theme.moss)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.background)
            case .signedOut:
                AuthFlowView()
            case .welcome(let kind):
                AuthSuccessView(kind: kind)
            case .onboarding:
                OnboardingFlowView(model: OnboardingViewModel(profile: auth.profile, uid: auth.uid))
            case .signedIn:
                MainTabView()
            }
        }
        .animation(.easeInOut, value: auth.state)
    }
}

/// Login/ Sign up navigation beg
struct AuthFlowView: View {
    enum Route: Hashable { case login, signUp }
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView(onSignUp: { path.append(.signUp) },
                        onLogin: { path.append(.login) })
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .login:  LoginView(onSignUp: { path = [.signUp] })
                    case .signUp: SignUpView()
                    }
                }
        }
        .tint(Theme.moss)
    }
}


#Preview("Full Flow") {
    RootView()
        .environmentObject(AuthViewModel.preview())
        .environmentObject(SavedJobsStore(fileName: "preview_saved_jobs.json"))
}
