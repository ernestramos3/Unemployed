import SwiftUI

// Each screen below matches a frame in the Figma "Preferences" section.
struct JobTitlesStep: View {
    @ObservedObject var model: OnboardingViewModel

    var body: some View {
        let picked = model.profile.jobTitles
        let similar = Catalog.similarTitles(to: picked)

        VStack(alignment: .leading, spacing: 0) {
            SearchPicker(label: "Job Title(s) / Role(s)", placeholder: "UX Designer",
                         catalog: Catalog.jobTitles, exclude: picked) { title in
                model.add(title, to: \.jobTitles)
            }

            if !picked.isEmpty {
                FlowLayout(spacing: 18, lineSpacing: 10) {
                    ForEach(picked, id: \.self) { title in
                        RemovableChip(title: title) { model.toggle(title, in: \.jobTitles) }
                    }
                }
                .padding(.top, 19)
            }

            if !similar.isEmpty {
                Text("Add Similar")
                    .font(Theme.semibold(20))
                    .padding(.top, 40)
                FlowLayout(spacing: 18, lineSpacing: 12) {
                    ForEach(similar, id: \.self) { title in
                        AddChip(title: title) { model.add(title, to: \.jobTitles) }
                    }
                }
                .padding(.top, 12)
            }
        }
    }
}

/// Job Type
struct JobTypeStep: View {
    @ObservedObject var model: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Job Type").font(Theme.semibold(20))
            ToggleChips(options: Catalog.jobTypes, selected: model.profile.jobTypes) {
                model.toggle($0, in: \.jobTypes)
            }
        }
    }
}

/// Experience
struct ExperienceStep: View {
    @ObservedObject var model: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Experience Level").font(Theme.semibold(20))
            ToggleChips(options: Catalog.experienceLevels, selected: model.profile.experienceLevels) {
                model.toggle($0, in: \.experienceLevels)
            }
        }
    }
}

/// lo
struct LocationStep: View {
    @ObservedObject var model: OnboardingViewModel
    @StateObject private var location = LocationHelper()

    var body: some View {
        let picked = model.profile.locations

        VStack(alignment: .leading, spacing: 0) {
            SearchPicker(label: "Location(s)", placeholder: "Austin",
                         catalog: Catalog.cities, exclude: picked) { city in
                model.add(city, to: \.locations)
            }

            if !picked.isEmpty {
                FlowLayout(spacing: 18, lineSpacing: 10) {
                    ForEach(picked, id: \.self) { city in
                        RemovableChip(title: city) { model.toggle(city, in: \.locations) }
                    }
                }
                .padding(.top, 19)
            }

            Text("Type")
                .font(Theme.semibold(20))
                .padding(.top, 60)
            ToggleChips(options: Catalog.workSettings, selected: model.profile.workSettings) {
                model.toggle($0, in: \.workSettings)
            }
            .padding(.top, 12)
        }
        .onAppear { location.requestCity() }
        .onChange(of: location.city) { _, city in
            // Pre-fill the user's current city once permission is granted.
            if let city { model.add(city, to: \.locations) }
        }
    }
}

/// Demographic and Veteran Status
struct VeteranStep: View {
    @ObservedObject var model: OnboardingViewModel

    var body: some View {
        SingleChoiceQuestion(question: "Do you identify as a Veteran?",
                             options: Catalog.veteranOptions,
                             selected: model.profile.veteranStatus) {
            model.choose($0, for: \.veteranStatus)
        }
    }
}

/// Disability
struct DisabilityStep: View {
    @ObservedObject var model: OnboardingViewModel

    var body: some View {
        SingleChoiceQuestion(question: "Do you have a disability?",
                             options: Catalog.disabilityOptions,
                             selected: model.profile.disabilityStatus) {
            model.choose($0, for: \.disabilityStatus)
        }
    }
}

/// Demographic about work authorization
struct WorkAuthorizationStep: View {
    @ObservedObject var model: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 52) {
            SingleChoiceQuestion(question: "Are you authorized to work in the US?",
                                 options: Catalog.yesNoOptions,
                                 selected: model.profile.workAuthorized) {
                model.choose($0, for: \.workAuthorized)
            }
            SingleChoiceQuestion(question: "Will you now or in the future require sponsorship?",
                                 options: Catalog.yesNoOptions,
                                 selected: model.profile.requiresSponsorship) {
                model.choose($0, for: \.requiresSponsorship)
            }
        }
    }
}

/// Completed set up: the logo builds itself.
/// The arrow-u draws inside the lime box, the wordmark slides in from the right and its
/// swooshes draw, then "swipe" comes from the left, "match" from the bottom, "get hired" from the right.
struct CompletedSetupView: View {
    @ObservedObject var model: OnboardingViewModel
    let onViewMatches: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var arrowDraw: CGFloat = 0
    @State private var showMark = false
    @State private var swooshDraw: CGFloat = 0
    @State private var showTagline = false
    @State private var showSwipe = false
    @State private var showMatch = false
    @State private var showHired = false
    @State private var showButton = false

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            VStack(spacing: 0) {
                Spacer()

                AppMark(size: 190, draw: arrowDraw)

                ArrowWordmark(size: 44, draw: swooshDraw)
                    .padding(.top, 40)
                    .offset(x: showMark ? 0 : width)

                Text("not for long.")
                    .font(Theme.semibold(18))
                    .foregroundStyle(Theme.skipGray)
                    .padding(.top, 2)
                    .opacity(showTagline ? 1 : 0)

                HStack(spacing: 12) {
                    pill("swipe", fill: Theme.lime)
                        .offset(x: showSwipe ? 0 : -width)
                    pill("match", fill: Theme.pillWhite)
                        .offset(y: showMatch ? 0 : height)
                    pill("get hired", fill: Theme.lime)
                        .offset(x: showHired ? 0 : width)
                }
                .padding(.top, 36)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Swipe, match, get hired")

                Spacer()

                if let error = model.errorMessage {
                    ErrorBanner(message: error).padding(.bottom, 12)
                }

                CTAButton(title: "View Matches", width: 191, action: onViewMatches)
                    .disabled(model.isSaving)
                    .opacity(showButton ? (model.isSaving ? 0.4 : 1) : 0)
                    .scaleEffect(showButton ? 1 : 0.7)
                    .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 25)
        .foregroundStyle(Theme.ink)
        .background(Theme.background)
        .task { await model.complete() }
        .task { await animateIn() }
    }

    private func pill(_ title: String, fill: Color) -> some View {
        Text(title)
            .font(Theme.semibold(17))
            .foregroundStyle(Theme.onLime)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(fill, in: Capsule())
    }

    private func animateIn() async {
        guard !reduceMotion else {
            arrowDraw = 1; showMark = true; swooshDraw = 1; showTagline = true
            showSwipe = true; showMatch = true; showHired = true; showButton = true
            return
        }
        let slide = Animation.spring(response: 0.6, dampingFraction: 0.82)

        try? await Task.sleep(for: .milliseconds(300))
        withAnimation(.easeInOut(duration: 1.1)) { arrowDraw = 1 }          // arrow travels down, swoops up
        try? await Task.sleep(for: .milliseconds(1150))
        withAnimation(slide) { showMark = true }                           // wordmark from the right
        try? await Task.sleep(for: .milliseconds(450))
        withAnimation(.easeInOut(duration: 0.7)) { swooshDraw = 1 }        // swooshes draw
        try? await Task.sleep(for: .milliseconds(450))
        withAnimation(.easeOut(duration: 0.4)) { showTagline = true }
        try? await Task.sleep(for: .milliseconds(200))
        withAnimation(slide) { showSwipe = true }                          // from the left
        try? await Task.sleep(for: .milliseconds(150))
        withAnimation(slide) { showMatch = true }                          // from the bottom
        try? await Task.sleep(for: .milliseconds(150))
        withAnimation(slide) { showHired = true }                          // from the right
        try? await Task.sleep(for: .milliseconds(450))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { showButton = true }
    }
}
