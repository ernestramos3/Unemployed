import Foundation
import SwiftUI
import FirebaseAuth

/// Handles Firebase Authentication and decides which part of the app to show.
@MainActor
final class AuthViewModel: ObservableObject {
    enum WelcomeKind: Equatable {
        case returningUser   // "Welcome Back to Unemployed!"
        case newUser         // "Welcome to Unemployed!"
    }

    enum State: Equatable {
        case loading
        case signedOut
        case welcome(WelcomeKind)
        case onboarding
        case signedIn
    }

    @Published private(set) var state: State = .loading
    @Published private(set) var profile = UserProfile()
    @Published private(set) var uid: String?
    @Published private(set) var isWorking = false
    @Published var errorMessage: String?

    private var pendingWelcome: WelcomeKind?
    private var profileLoaded = false
    private var listener: AuthStateDidChangeListenerHandle?

    nonisolated static var isRunningInPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    init(previewState: State? = nil) {
        if let previewState {
            state = previewState
            profile = UserProfile(username: "nnpeas17", email: "npeasley@utexas.edu")
            return
        }
        if Self.isRunningInPreview {
            state = .signedOut
            return
        }
        listener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in self?.handleAuthChange(user) }
        }
    }

    static func preview(_ state: State = .signedOut, error: String? = nil) -> AuthViewModel {
        let model = AuthViewModel(previewState: state)
        model.errorMessage = error
        return model
    }

    // Login / sign up

    func logIn(email: String, password: String) async {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty, !password.isEmpty else {
            show("Please Enter Your Email and Password")
            return
        }
        await run(welcome: .returningUser) {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
        }
    }

    func signUp(username: String, email: String, password: String) async {
        let username = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if username.isEmpty { show("Please Enter a Username"); return }
        if !email.contains("@") || !email.contains(".") { show("Please Enter a Valid Email"); return }
        if password.count < 6 { show("Password Must Be at Least 6 Characters"); return }

        await run(welcome: .newUser) {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let change = result.user.createProfileChangeRequest()
            change.displayName = username
            try await change.commitChanges()

            self.profile = UserProfile(username: username, email: email)
            self.profileLoaded = true
            // Create users/{uid} in Firestore. Onboarding saves again later,
            // so a failure here isn't fatal.
            do {
                try await ProfileStore.createUser(uid: result.user.uid, username: username, email: email)
            } catch {
                print("⚠️ Firestore createUser failed:", error)
            }
        }
    }

    // Navigation

    func continueFromWelcome() {
        Task {
            if !profileLoaded { await loadProfile() }
            state = profile.onboardingComplete ? .signedIn : .onboarding
        }
    }

    func backToWelcome() {
        state = .welcome(.newUser)
    }

    func finishOnboarding(with profile: UserProfile) {
        self.profile = profile
        state = .signedIn
    }

    func signOut() {
        if Self.isRunningInPreview { state = .signedOut; return }
        try? Auth.auth().signOut()
    }

    func clearError() {
        errorMessage = nil
    }

    // for the preview use only
    private func run(welcome: WelcomeKind, _ work: () async throws -> Void) async {
        if Self.isRunningInPreview {
            show("Login Only Works in the Simulator")
            return
        }
        errorMessage = nil
        isWorking = true
        pendingWelcome = welcome
        defer { isWorking = false }
        do {
            try await work()
        } catch {
            pendingWelcome = nil
            show(message(for: error))
        }
    }

    // authenticate
    private func handleAuthChange(_ user: User?) {
        guard let user else {
            uid = nil
            profile = UserProfile()
            profileLoaded = false
            state = .signedOut
            return
        }
        uid = user.uid

        if let kind = pendingWelcome {
            // Just logged in or signed up: show the welcome screen.
            pendingWelcome = nil
            state = .welcome(kind)
            if kind == .returningUser {
                profileLoaded = false
                Task { await loadProfile() }
            }
        } else if state == .signedOut || state == .loading {
            // App relaunched with a saved session.
            state = .loading
            Task {
                await loadProfile()
                state = profile.onboardingComplete ? .signedIn : .onboarding
            }
        }
    }

    // pulling data frome existing profile
    private func loadProfile() async {
        guard let user = Auth.auth().currentUser else { return }
        do {
            if let saved = try await ProfileStore.load(uid: user.uid) {
                profile = saved
            } else {
                profile = UserProfile(username: user.displayName ?? "", email: user.email ?? "")
            }
        } catch {
            print("⚠️ Firestore load failed:", error)
            profile = UserProfile(username: user.displayName ?? "", email: user.email ?? "")
        }
        profileLoaded = true
    }

    private func show(_ message: String) {
        withAnimation { errorMessage = message }
    }

    /// Firebase errors into the banner messages from the designs.
    private func message(for error: Error) -> String {
        switch AuthErrorCode(rawValue: (error as NSError).code) {
        case .userNotFound:                  return "No Account Associated With This Email"
        case .emailAlreadyInUse:             return "Email Already Associated with an Account"
        case .wrongPassword, .invalidCredential:
                                             return "Incorrect Email or Password"
        case .invalidEmail:                  return "Please Enter a Valid Email"
        case .weakPassword:                  return "Password Must Be at Least 6 Characters"
        case .networkError:                  return "Network Error. Check Your Connection"
        case .tooManyRequests:               return "Too Many Attempts. Try Again Later"
        default:                             return error.localizedDescription
        }
    }
}
