import SwiftUI

/// Runs the onboarding screens in order and saves answers to Firestore
/// saves to Firestore after each one
struct OnboardingFlowView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @StateObject private var model: OnboardingViewModel

    init(model: OnboardingViewModel) {
        _model = StateObject(wrappedValue: model)
    }

    var body: some View {
        Group {
            if model.step == .complete {
                CompletedSetupView(model: model) {
                    auth.finishOnboarding(with: model.profile)
                }
            } else {
                OnboardingScaffold(progress: model.step.progress,
                                   showSkip: model.step.isSkippable,
                                   isBusy: model.isSaving,
                                   error: model.errorMessage,
                                   onSkip: { Task { await model.skip() } },
                                   onBack: goBack,
                                   onNext: { Task { await model.next() } }) {
                    stepContent
                        .id(model.step)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut, value: model.step)
    }

    @ViewBuilder private var stepContent: some View {
        switch model.step {
        case .jobTitles:         JobTitlesStep(model: model)
        case .jobType:           JobTypeStep(model: model)
        case .experience:        ExperienceStep(model: model)
        case .location:          LocationStep(model: model)
        case .veteran:           VeteranStep(model: model)
        case .disability:        DisabilityStep(model: model)
        case .workAuthorization: WorkAuthorizationStep(model: model)
        case .complete:          EmptyView()
        }
    }

    private func goBack() {
        if !model.back() { auth.backToWelcome() }
    }
}

#Preview("Job Titles") {
    OnboardingFlowView(model: .preview(.jobTitles))
        .environmentObject(AuthViewModel.preview(.onboarding))
}

#Preview("Job Type") {
    OnboardingFlowView(model: .preview(.jobType))
        .environmentObject(AuthViewModel.preview(.onboarding))
}

#Preview("Experience") {
    OnboardingFlowView(model: .preview(.experience))
        .environmentObject(AuthViewModel.preview(.onboarding))
}

#Preview("Location") {
    OnboardingFlowView(model: .preview(.location))
        .environmentObject(AuthViewModel.preview(.onboarding))
}

#Preview("Veteran") {
    OnboardingFlowView(model: .preview(.veteran))
        .environmentObject(AuthViewModel.preview(.onboarding))
}

#Preview("Disability") {
    OnboardingFlowView(model: .preview(.disability))
        .environmentObject(AuthViewModel.preview(.onboarding))
}

#Preview("Work Authorization") {
    OnboardingFlowView(model: .preview(.workAuthorization))
        .environmentObject(AuthViewModel.preview(.onboarding))
}

#Preview("Completed Set Up") {
    OnboardingFlowView(model: .preview(.complete))
        .environmentObject(AuthViewModel.preview(.onboarding))
}
