// the basis of what is shown on the discover tab

import SwiftUI

struct DiscoverView: View {
    @StateObject private var viewModel = DiscoverViewModel()
    @EnvironmentObject private var savedJobs: SavedJobsStore
    @EnvironmentObject private var auth: AuthViewModel
    @State private var buttonSwipe: SwipeDirection?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                cardStack
                actionButtons
            }
            .padding()
            .navigationTitle("Discover")
            .onAppear { viewModel.configure(store: savedJobs, profile: auth.profile) }
            .onChange(of: auth.profile) { _, newProfile in viewModel.updateProfile(newProfile) }
            .onChange(of: savedJobs.savedJobs) { _, _ in viewModel.dropSavedJobs() }
        }
    }

    private var cardStack: some View {
        ZStack {
            if viewModel.deck.isEmpty {
                emptyState
            } else {
                // Only render the top 3 cards
                let visible = Array(viewModel.deck.suffix(3))
                ForEach(Array(visible.enumerated()), id: \.element.id) { index, job in
                    let depth = visible.count - 1 - index // top card
                    SwipeCardView(
                        job: job,
                        isTopCard: depth == 0,
                        matchedLabels: viewModel.matchedLabels(for: job),
                        buttonSwipe: $buttonSwipe
                    ) { direction in
                        viewModel.swipe(direction)
                    }
                    .scaleEffect(1 - CGFloat(depth) * 0.04)
                    .offset(y: CGFloat(depth) * 12)
                    .animation(.spring(response: 0.3), value: viewModel.deck.count)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
            Text("You're all caught up")
                .font(.headline)
            Button("Start over") { viewModel.reset() }
                .buttonStyle(.borderedProminent)
        }
    }

    // if instead of swiping they decide to just click the buttons
    private var actionButtons: some View {
        HStack(spacing: 32) {
            circleButton(symbol: "xmark", color: .red, size: 64) {
                buttonSwipe = .left
            }
            .disabled(viewModel.topJob == nil || buttonSwipe != nil)

            circleButton(symbol: "arrow.uturn.backward", color: .gray, size: 48) {
                withAnimation { viewModel.undo() }
            }
            .disabled(!viewModel.canUndo || buttonSwipe != nil)

            circleButton(symbol: "heart.fill", color: .green, size: 64) {
                buttonSwipe = .right
            }
            .disabled(viewModel.topJob == nil || buttonSwipe != nil)
        }
    }

    private func circleButton(symbol: String, color: Color, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(color)
                .frame(width: size, height: size)
                .background(Color(.systemBackground))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
        }
    }
}

#Preview {
    DiscoverView()
        .environmentObject(AuthViewModel.preview(.signedIn))
        .environmentObject(SavedJobsStore(fileName: "preview_saved_jobs.json"))
}
