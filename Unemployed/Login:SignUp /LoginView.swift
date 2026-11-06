import SwiftUI

/// "Login" and "Login Unsucessful" 
struct LoginView: View {
    @EnvironmentObject private var auth: AuthViewModel
    let onSignUp: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var unavailableProvider: String?
    @FocusState private var focus: Field?

    enum Field { case email, password }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("Login Now")
                    .font(Theme.display(34))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 8)

                ErrorSlot(message: auth.errorMessage)
                    .padding(.top, 37)

                VStack(spacing: 45) {
                    UnderlineField(placeholder: "Email", text: $email,
                                   contentType: .emailAddress, keyboard: .emailAddress)
                        .focused($focus, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focus = .password }

                    UnderlineField(placeholder: "Password", text: $password,
                                   isSecure: true, contentType: .password)
                        .focused($focus, equals: .password)
                        .submitLabel(.go)
                        .onSubmit(logIn)
                }
                .padding(.top, 36)

                Text("Or login with")
                    .font(Theme.regular(18))
                    .foregroundStyle(Theme.skipGray)
                    .padding(.top, 45)

                VStack(spacing: 21) {
                    SocialButton(title: "Login with Facebook", assetName: "facebookLogo",
                                 fallbackSymbol: "f.circle.fill",
                                 fallbackColor: Color(red: 0.23, green: 0.35, blue: 0.6)) {
                        unavailableProvider = "Facebook"
                    }
                    SocialButton(title: "Login with Google", assetName: "googleLogo",
                                 fallbackSymbol: "g.circle.fill",
                                 fallbackColor: Color(red: 0.26, green: 0.52, blue: 0.96)) {
                        unavailableProvider = "Google"
                    }
                    Button(action: onSignUp) {
                        (Text("Don't have an account? ").font(Theme.regular(18))
                         + Text("Sign-up").font(Theme.bold(18)))
                            .underline()
                            .foregroundStyle(Theme.ink)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 24)

                AuthSubmitButton(title: "Login", isLoading: auth.isWorking, action: logIn)
                    .padding(.top, 40)
            }
            .padding(.horizontal, 47)
            .padding(.bottom, 24)
        }
        .background(Theme.background)
        .scrollDismissesKeyboard(.interactively)
        .onDisappear { auth.clearError() }
        .alert("Not Available Yet",
               isPresented: Binding(get: { unavailableProvider != nil },
                                    set: { if !$0 { unavailableProvider = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(unavailableProvider ?? "This") login isn't part of the alpha. Please use your email and password.")
        }
    }

    private func logIn() {
        focus = nil
        Task { await auth.logIn(email: email, password: password) }
    }
}

#Preview("Login") {
    NavigationStack { LoginView(onSignUp: {}) }
        .environmentObject(AuthViewModel.preview())
}

#Preview("Login – Unsuccessful") {
    NavigationStack { LoginView(onSignUp: {}) }
        .environmentObject(AuthViewModel.preview(error: "No Account Associated With This Email"))
}
