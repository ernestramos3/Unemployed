// Swipe left and/or right mechanism

import SwiftUI

enum SwipeDirection {
    case left   // pass
    case right  // like / save
}

@MainActor
final class DiscoverViewModel: ObservableObject {
    /// The LAST element is the top card on screen.
    @Published private(set) var deck: [Job] = []
    @Published private(set) var passedJobs: [Job] = []

    /// Shared store for liked jobs
    private weak var store: SavedJobsStore?
    private var profile = UserProfile()

    /// History so the user can undo their last swipe
    private var history: [(job: Job, direction: SwipeDirection)] = []
    private let allJobs: [Job]

    var topJob: Job? { deck.last }
    var canUndo: Bool { !history.isEmpty }

    init(jobs: [Job] = MockJobs.all) {
        allJobs = jobs
        deck = jobs.shuffled()
    }

    /// Connects the shared store and the user's preferences, then builds the deck.
    ///  this is only called once.
    func configure(store: SavedJobsStore, profile: UserProfile) {
        guard self.store == nil else {
            if profile != self.profile { updateProfile(profile) }
            return
        }
        self.store = store
        self.profile = profile
        rebuildDeck()
    }

    /// Removes cards the user has already saved (e.g. once their list
    /// finishes loading from Firestore).
    func dropSavedJobs() {
        guard let store else { return }
        deck.removeAll { store.isSaved($0) }
    }

    /// Call when the user edits their preferences
    /// gives the jobs different scores
    func updateProfile(_ profile: UserProfile) {
        self.profile = profile
        deck = ordered(deck)
    }

    // sets the score
    func score(for job: Job) -> Int {
        JobMatcher.score(job, for: profile)
    }

    func matchedLabels(for job: Job) -> [String] {
        JobMatcher.matchedLabels(job, for: profile)
    }

    /// Best matches end up at the at the top of the stack
    /// (end of the array)
    private func ordered(_ jobs: [Job]) -> [Job] {
        jobs.map { (job: $0, score: score(for: $0), tiebreak: Double.random(in: 0..<1)) }
            .sorted { ($0.score, $0.tiebreak) < ($1.score, $1.tiebreak) }
            .map(\.job)
    }

    private func rebuildDeck() {
        let unsaved = allJobs.filter { !(store?.isSaved($0) ?? false) }
        deck = ordered(unsaved)
    }

    /// Records a swipe on the top card
    func swipe(_ direction: SwipeDirection) {
        guard let job = deck.popLast() else { return }
        switch direction {
        case .right: store?.save(job)
        case .left:  passedJobs.append(job)
        }
        history.append((job, direction))

        // makes it seem infinite
        if deck.count < 3 && !passedJobs.isEmpty {
            let recycled = ordered(passedJobs)
            passedJobs.removeAll()
            deck.insert(contentsOf: recycled, at: 0)
        }
    }

    ///undos the prev action
    func undo() {
        guard let last = history.popLast() else { return }
        switch last.direction {
        case .right: store?.remove(last.job)
        case .left:  passedJobs.removeAll { $0.id == last.job.id }
        }
        deck.removeAll { $0.id == last.job.id } // in case it was recycled
        deck.append(last.job)
    }

    /// Starts over with a fresh deck of jobs that aren't saved yet
    func reset() {
        passedJobs.removeAll()
        history.removeAll()
        rebuildDeck()
    }
}
