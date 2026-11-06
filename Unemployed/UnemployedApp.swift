import SwiftUI
import FirebaseCore

@main
struct UnemployedApp: App {
    @StateObject private var auth: AuthViewModel
    /// Jobs the user swiped right on. Shared by Discover and the Saved tab.
    @StateObject private var savedJobs = SavedJobsStore()

    init() {
        // Reads GoogleService-Info.plist. The app will crash here with a clear
        // message if that file hasn't been added to the Unemployed folder yet.
        if !AuthViewModel.isRunningInPreview {
            FirebaseApp.configure()
        }
        _auth = StateObject(wrappedValue: AuthViewModel())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(savedJobs)
                // Each account gets its own saved jobs.
                .onAppear { savedJobs.switchUser(to: auth.uid) }
                .onChange(of: auth.uid) { _, newUID in savedJobs.switchUser(to: newUID) }
                .preferredColorScheme(.dark) // logo palette is dark + lime
        }
    }
}
