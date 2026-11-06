// the data structure for the job card
import Foundation

enum JobType: String, CaseIterable, Identifiable, Codable {
    case fullTime = "Full-Time"
    case partTime = "Part-Time"
    case internship = "Internship"
    case contract = "Contract"

    var id: String { rawValue }
}

enum WorkMode: String, CaseIterable, Identifiable, Codable {
    case inPerson = "In-Person"
    case remote = "Remote"
    case hybrid = "Hybrid"

    var id: String { rawValue }
}

enum ExperienceLevel: String, CaseIterable, Identifiable, Codable {
    case entry = "Entry-Level"
    case mid = "Mid-Level"
    case senior = "Senior"
    case executive = "Executive"

    var id: String { rawValue }
}

/// How the user applies once they've liked a job (used by the Likes/Saved screen) (not fr)
enum ApplyMethod: String, CaseIterable, Identifiable, Codable {
    case easyApply = "Easy Apply"
    case manual = "Apply Manually"
    case companySite = "Company Site"

    var id: String { rawValue }
}

struct Job: Identifiable, Hashable, Codable {
    /// Stable ID built from company + title, so a saved job still matches
    /// the same mock job after the app relaunches (a random UUID would not).
    var id: String { "\(company)|\(title)" }
    let title: String
    let company: String
    let location: String
    let jobType: JobType
    let workMode: WorkMode
    let salaryMin: Int          // annual USD, or hourly if isHourly == true
    let salaryMax: Int
    var isHourly: Bool = false
    let summary: String
    let tags: [String]
    let postedDaysAgo: Int
    let applyMethod: ApplyMethod
    let logoSymbol: String      // SF Symbol name used as a placeholder logo
    var experienceLevel: ExperienceLevel = .entry

    var payDisplay: String {
        if isHourly {
            return "$\(salaryMin)–\(salaryMax)/hr"
        }
        return "$\(salaryMin / 1000)k–\(salaryMax / 1000)k/yr"
    }

    var postedDisplay: String {
        postedDaysAgo == 0 ? "Posted today" : "Posted \(postedDaysAgo)d ago"
    }
}
