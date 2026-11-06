import SwiftUI

/// The main app after login/signup
struct MainTabView: View {
    var body: some View {
        TabView {
            DiscoverView()
                .tabItem { Label("Discover", systemImage: "rectangle.stack") }
            SavedView()
                .tabItem { Label("Saved", systemImage: "heart") }
            BlankScreen(title: "Notifications")
                .tabItem { Label("Notifications", systemImage: "bell") }
            ProfileScreen()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
        .tint(Theme.moss)
    }
}

// blank (for now)
struct BlankScreen: View {
    let title: String

    var body: some View {
        NavigationStack {
            Theme.background
                .ignoresSafeArea(edges: .top)
                .navigationTitle(title)
        }
    }
}

/// Blank too, except for Sign Out so testers can replay the flow
struct ProfileScreen: View {
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                CTAButton(title: "Sign Out") { auth.signOut() }
                    .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity)
            .background(Theme.background)
            .navigationTitle("Profile")
        }
    }
}

#Preview("Main Tabs") {
    MainTabView()
        .environmentObject(AuthViewModel.preview(.signedIn))
        .environmentObject(SavedJobsStore(fileName: "preview_saved_jobs.json"))
}
