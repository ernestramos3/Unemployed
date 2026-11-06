import Foundation
import SwiftUI
import UserNotifications

/// Holds the answers while the user goes through onboarding and saves them to Firestore
@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case jobTitles, jobType, experience, location, veteran, disability, workAuthorization, complete

        /// Progress bar fill, matching the widths in Figma (out of 380).
        var progress: CGFloat {
            switch self {
            case .jobTitles:         68 / 380
            case .jobType:           121 / 380
            case .experience:        192 / 380
            case .location:          244 / 380
            case .veteran:           264 / 380
            case .disability:        323 / 380
            case .workAuthorization: 355 / 380
            case .complete:          1
            }
        }
        // skipped
        var isSkippable: Bool {
            self == .veteran || self == .disability || self == .workAuthorization
        }
    }

    @Published var step: Step
    @Published var profile: UserProfile
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    private let uid: String?

    init(profile: UserProfile, uid: String?, step: Step = .jobTitles) {
        self.profile = profile
        self.uid = uid
        self.step = step
    }

    static func preview(_ step: Step = .jobTitles) -> OnboardingViewModel {
        var sample = UserProfile(username: "nnpeas17", email: "npeasley@utexas.edu")
        sample.jobTitles = ["User Researcher", "Design Engineer"]
        sample.jobTypes = ["Full-Time"]
        sample.locations = ["Austin"]
        return OnboardingViewModel(profile: sample, uid: nil, step: step)
    }

    // Buttons

    func next() async {
        if let problem = validationError() {
            withAnimation { errorMessage = problem }
            return
        }
        errorMessage = nil
        guard await save() else { return }
        advance()
    }

    func skip() async {
        switch step {
        case .veteran:           profile.veteranStatus = nil
        case .disability:        profile.disabilityStatus = nil
        case .workAuthorization: profile.workAuthorized = nil; profile.requiresSponsorship = nil
        default: break
        }
        errorMessage = nil
        guard await save() else { return }
        advance()
    }

    func back() -> Bool {
        errorMessage = nil
        guard let previous = Step(rawValue: step.rawValue - 1) else { return false }
        withAnimation(.easeInOut) { step = previous }
        return true
    }

    func complete() async {
        if !AuthViewModel.isRunningInPreview {
            // Shows the iOS "Allow Unemployed to send you notifications?" prompt.
            let granted = (try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])) ?? false
            profile.notificationsEnabled = granted
        }
        profile.onboardingComplete = true
        _ = await save()
    }

    func toggle(_ value: String, in keyPath: WritableKeyPath<UserProfile, [String]>) {
        if let index = profile[keyPath: keyPath].firstIndex(of: value) {
            profile[keyPath: keyPath].remove(at: index)
        } else {
            profile[keyPath: keyPath].append(value)
        }
        errorMessage = nil
    }

    func add(_ value: String, to keyPath: WritableKeyPath<UserProfile, [String]>) {
        guard !profile[keyPath: keyPath].contains(value) else { return }
        profile[keyPath: keyPath].append(value)
        errorMessage = nil
    }

    func choose(_ value: String, for keyPath: WritableKeyPath<UserProfile, String?>) {
        profile[keyPath: keyPath] = profile[keyPath: keyPath] == value ? nil : value
    }

    // Private

    private func advance() {
        guard let next = Step(rawValue: step.rawValue + 1) else { return }
        withAnimation(.easeInOut) { step = next }
    }

    private func validationError() -> String? {
        switch step {
        case .jobTitles where profile.jobTitles.isEmpty:
            return "Please Add at Least One Job Title"
        case .jobType where profile.jobTypes.isEmpty:
            return "Please Select at Least One Job Type"
        case .experience where profile.experienceLevels.isEmpty:
            return "Please Select an Experience Level"
        case .location where profile.workSettings.isEmpty:
            return "Please Choose In-Person, Remote, or Hybrid"
        case .location where profile.locations.isEmpty && profile.workSettings != ["Remote"]:
            return "Please Add at Least One Location"
        default:
            return nil
        }
    }

    /// Saves to users/{uid}. Returns false (and shows a banner) if it failed.
    private func save() async -> Bool {
        guard let uid, !AuthViewModel.isRunningInPreview else { return true }
        isSaving = true
        defer { isSaving = false }
        do {
            try await ProfileStore.save(profile, uid: uid)
            return true
        } catch {
            print("⚠️ Firestore save failed:", error)
            withAnimation { errorMessage = ProfileStore.message(for: error) }
            return false
        }
    }
}
