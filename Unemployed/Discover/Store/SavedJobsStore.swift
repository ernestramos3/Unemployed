//
//  SavedJobsStore.swift
//  Unemployed – Discover
//
//  Shared store for every job the CURRENT USER swiped right on. Each account
//  has its own list:
//    • kept on the phone in saved_jobs_<uid>.json (instant, works offline)
//    • synced to Firestore at users/{uid}.savedJobs so it follows the
//      account to other devices
//
//  UnemployedApp calls `switchUser(to:)` whenever someone signs in or out.
//
//  Saved tab usage:
//      @EnvironmentObject var savedJobs: SavedJobsStore
//      List(savedJobs.savedJobs) { saved in Text(saved.job.title) }
//

import Foundation
import FirebaseFirestore

/// Where the user is with a saved job. Handy for the Saved tab and
/// for "you haven't applied yet" reminders in the Notifications tab.
enum ApplicationStatus: String, CaseIterable, Identifiable, Codable {
    case saved = "Saved"
    case applied = "Applied"

    var id: String { rawValue }
}

struct SavedJob: Identifiable, Hashable, Codable {
    let job: Job
    let savedAt: Date
    var status: ApplicationStatus = .saved

    var id: String { job.id }
}

@MainActor
final class SavedJobsStore: ObservableObject {
    /// Newest first. Always belongs to `currentUID`.
    @Published private(set) var savedJobs: [SavedJob] = []

    /// The signed-in account this list belongs to (nil = nobody signed in).
    private(set) var currentUID: String?

    /// Previews pass a fixed file name and skip Firestore.
    private let previewFileName: String?

    init(previewFileName: String? = nil) {
        self.previewFileName = previewFileName
        Self.deleteLegacySharedFile()
        if previewFileName != nil { savedJobs = loadLocal() }
    }

    /// Kept so existing previews like SavedJobsStore(fileName: "...") still compile.
    convenience init(fileName: String) {
        self.init(previewFileName: fileName)
    }

    // MARK: - Switching accounts

    /// Call when the signed-in user changes. Loads that user's list
    /// (or clears it when signed out).
    func switchUser(to uid: String?) {
        guard previewFileName == nil, uid != currentUID else { return }
        currentUID = uid
        savedJobs = uid == nil ? [] : loadLocal()

        guard let uid else { return }
        Task { await pullFromFirestore(uid: uid) }
    }

    // MARK: - Queries

    var count: Int { savedJobs.count }

    func isSaved(_ job: Job) -> Bool {
        savedJobs.contains { $0.id == job.id }
    }

    func jobs(with status: ApplicationStatus) -> [SavedJob] {
        savedJobs.filter { $0.status == status }
    }

    // MARK: - Changes (each one saves locally and to Firestore)

    func save(_ job: Job) {
        guard !isSaved(job) else { return }
        savedJobs.insert(SavedJob(job: job, savedAt: Date()), at: 0)
        persist()
    }

    func remove(_ job: Job) {
        savedJobs.removeAll { $0.id == job.id }
        persist()
    }

    /// For swipe-to-delete in a List: .onDelete { store.remove(atOffsets: $0) }
    func remove(atOffsets offsets: IndexSet) {
        savedJobs.remove(atOffsets: offsets)
        persist()
    }

    func setStatus(_ status: ApplicationStatus, for job: Job) {
        guard let index = savedJobs.firstIndex(where: { $0.id == job.id }) else { return }
        savedJobs[index].status = status
        persist()
    }

    func removeAll() {
        savedJobs.removeAll()
        persist()
    }

    private func persist() {
        saveLocal()
        if let uid = currentUID, previewFileName == nil {
            let snapshot = savedJobs
            Task { await pushToFirestore(snapshot, uid: uid) }
        }
    }

    // MARK: - Local file (one per account)

    private var fileURL: URL? {
        let name: String
        if let previewFileName { name = previewFileName }
        else if let uid = currentUID { name = "saved_jobs_\(uid).json" }
        else { return nil }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(name)
    }

    private func loadLocal() -> [SavedJob] {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([SavedJob].self, from: data)) ?? []
    }

    private func saveLocal() {
        guard let url = fileURL else { return }
        do {
            try JSONEncoder().encode(savedJobs).write(to: url, options: .atomic)
        } catch {
            print("SavedJobsStore: could not save locally – \(error)")
        }
    }

    /// The old version used one file for everyone on the phone. Remove it.
    private static func deleteLegacySharedFile() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? FileManager.default.removeItem(at: documents.appendingPathComponent("saved_jobs.json"))
    }

    // MARK: - Firestore (users/{uid}.savedJobs)
    // Only the job ID, status, and date are stored; the full job is looked up
    // in MockJobs, so Firestore stays small.

    private func userDoc(_ uid: String) -> DocumentReference {
        Firestore.firestore().collection("users").document(uid)
    }

    private func pushToFirestore(_ jobs: [SavedJob], uid: String) async {
        let entries: [[String: Any]] = jobs.map {
            ["jobId": $0.job.id, "status": $0.status.rawValue, "savedAt": Timestamp(date: $0.savedAt)]
        }
        do {
            try await userDoc(uid).setData(["savedJobs": entries], merge: true)
        } catch {
            print("SavedJobsStore: Firestore save failed – \(error)")
        }
    }

    private func pullFromFirestore(uid: String) async {
        do {
            let snapshot = try await userDoc(uid).getDocument()
            // Signed into a different account while this was loading? Ignore it.
            guard uid == currentUID else { return }
            guard let entries = snapshot.data()?["savedJobs"] as? [[String: Any]] else {
                // Nothing in Firestore yet: upload whatever is on this phone.
                if !savedJobs.isEmpty { await pushToFirestore(savedJobs, uid: uid) }
                return
            }
            let jobsByID = Dictionary(MockJobs.all.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
            let remote: [SavedJob] = entries.compactMap { entry in
                guard let id = entry["jobId"] as? String, let job = jobsByID[id] else { return nil }
                let status = ApplicationStatus(rawValue: entry["status"] as? String ?? "") ?? .saved
                let date = (entry["savedAt"] as? Timestamp)?.dateValue() ?? Date()
                return SavedJob(job: job, savedAt: date, status: status)
            }
            savedJobs = remote
            saveLocal()
        } catch {
            print("SavedJobsStore: Firestore load failed – \(error)")
        }
    }
}
