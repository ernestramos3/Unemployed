// the basis of the saved tab in the application

import SwiftUI

struct SavedView: View {
    @EnvironmentObject private var savedJobs: SavedJobsStore
    @State private var filter: ApplicationStatus = .saved
    @State private var jobToApply: SavedJob?

    private var visibleJobs: [SavedJob] {
        savedJobs.jobs(with: filter)
    } // shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("Filter", selection: $filter) {
                    ForEach(ApplicationStatus.allCases) { status in
                        Text("\(status.rawValue) (\(savedJobs.jobs(with: status).count))").tag(status)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if visibleJobs.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(visibleJobs) { saved in
                            SavedJobRow(saved: saved) { jobToApply = saved }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .swipeActions {
                                    Button(role: .destructive) {
                                        savedJobs.remove(saved.job)
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .padding(.top, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Theme.background)
            .navigationTitle("Saved")
            .sheet(item: $jobToApply) { saved in
                ApplySheet(saved: saved) {
                    savedJobs.setStatus(.applied, for: saved.job)
                }
                .presentationDetents([.medium])
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: filter == .saved ? "heart" : "paperplane")
                .font(.system(size: 44))
                .foregroundStyle(Theme.lime)
            Text(filter == .saved ? "No saved jobs yet" : "Nothing applied to yet")
                .font(Theme.semibold(18))
                .foregroundStyle(Theme.ink)
            Text(filter == .saved ? "Swipe right on a job in Discover to save it here."
                                  : "Apply to a saved job and it'll show up here.")
                .font(Theme.regular(15))
                .foregroundStyle(Theme.placeholderGray)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}


struct SavedJobRow: View {
    let saved: SavedJob
    let onApply: () -> Void

    private var job: Job { saved.job }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: job.logoSymbol)
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.lime)
                    .frame(width: 48, height: 48)
                    .background(Theme.sage)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text(job.title)
                        .font(Theme.semibold(17))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(2)
                    Text("\(job.company) · \(job.location)")
                        .font(Theme.regular(14))
                        .foregroundStyle(Theme.placeholderGray)
                    Text("\(job.payDisplay) · \(job.jobType.rawValue) · \(job.workMode.rawValue)")
                        .font(Theme.regular(13))
                        .foregroundStyle(Theme.skipGray)
                }
                Spacer(minLength: 0)
            }

            HStack {
                Text("Saved \(saved.savedAt.formatted(.relative(presentation: .named)))")
                    .font(Theme.regular(12))
                    .foregroundStyle(Theme.placeholderGray)
                Spacer()
                if saved.status == .applied {
                    Label("Applied", systemImage: "checkmark.circle.fill")
                        .font(Theme.semibold(14))
                        .foregroundStyle(Theme.lime)
                } else {
                    Button(action: onApply) {
                        Text(job.applyMethod.rawValue)
                            .font(Theme.semibold(14))
                            .foregroundStyle(Theme.onLime)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Theme.lime, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}


struct ApplySheet: View {
    let saved: SavedJob
    let onApplied: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var job: Job { saved.job }

    private var explanation: String {
        switch job.applyMethod {
        case .easyApply:   return "Send your Unemployed profile to \(job.company) in one tap."
        case .manual:      return "Fill out \(job.company)'s application form yourself."
        case .companySite: return "Continue to \(job.company)'s careers page to finish applying."
        }
    }

    var body: some View {
        VStack(spacing: 18) {
            Text(job.applyMethod.rawValue)
                .font(Theme.display(28))
                .foregroundStyle(Theme.lime)
            VStack(spacing: 4) {
                Text(job.title).font(Theme.semibold(18)).foregroundStyle(Theme.ink)
                Text(job.company).font(Theme.regular(15)).foregroundStyle(Theme.placeholderGray)
            }
            Text(explanation)
                .font(Theme.regular(15))
                .foregroundStyle(Theme.skipGray)
                .multilineTextAlignment(.center)
            Spacer()
            CTAButton(title: "Apply", width: 200) {
                onApplied()
                dismiss()
            }
            Button("Not now") { dismiss() }
                .font(Theme.regular(15))
                .foregroundStyle(Theme.skipGray)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }
}

#Preview {
    let store = SavedJobsStore(fileName: "preview_saved_jobs.json")
    MockJobs.all.prefix(4).forEach { store.save($0) }
    return SavedView()
        .environmentObject(store)
        .preferredColorScheme(.dark)
}
