import SwiftUI

/// Sign-Up and Email Already has an Account
struct SignUpView: View {
    @EnvironmentObject private var auth: AuthViewModel

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var unavailableProvider: String?
    @FocusState private var focus: Field?

    enum Field { case username, email, password }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("SignUp Now")
                    .font(Theme.display(34))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 8)

                ErrorSlot(message: auth.errorMessage)
                    .padding(.top, 28)

                VStack(spacing: 45) {
                    UnderlineField(placeholder: "Username", text: $username, contentType: .username)
                        .focused($focus, equals: .username)
                        .submitLabel(.next)
                        .onSubmit { focus = .email }

                    UnderlineField(placeholder: "Email", text: $email,
                                   contentType: .emailAddress, keyboard: .emailAddress)
                        .focused($focus, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focus = .password }

                    UnderlineField(placeholder: "Password", text: $password,
                                   isSecure: true, contentType: .newPassword)
                        .focused($focus, equals: .password)
                        .submitLabel(.done)
                        .onSubmit(signUp)
                }
                .padding(.top, 27)

                Text("Or login with")
                    .font(Theme.regular(18))
                    .foregroundStyle(Theme.skipGray)
                    .padding(.top, 52)

                VStack(spacing: 16) {
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
                }
                .padding(.top, 24)

                AuthSubmitButton(title: "sign-up", isLoading: auth.isWorking, action: signUp)
                    .padding(.top, 36)
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
            Text("\(unavailableProvider ?? "This") sign-up isn't part of the alpha. Please use your email and a password.")
        }
    }

    private func signUp() {
        focus = nil
        Task { await auth.signUp(username: username, email: email, password: password) }
    }
}

#Preview("Sign Up") {
    NavigationStack { SignUpView() }
        .environmentObject(AuthViewModel.preview())
}

#Preview("Sign Up – Email Taken") {
    NavigationStack { SignUpView() }
        .environmentObject(AuthViewModel.preview(error: "Email Already Associated with an Account"))
}
