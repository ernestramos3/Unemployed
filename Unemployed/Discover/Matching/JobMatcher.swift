//  Scores how well a job fits the user's onboarding preferences
import Foundation

enum JobMatcher {
    // How much each kind of match is worth
    // higher score = higher priority
    static let titleWeight = 4
    static let jobTypeWeight = 2
    static let workSettingWeight = 2
    static let locationWeight = 2
    static let experienceWeight = 1

    static func score(_ job: Job, for profile: UserProfile) -> Int {
        reasons(job, for: profile).reduce(0) { $0 + $1.weight }
    }

    /// What matched
    static func matchedLabels(_ job: Job, for profile: UserProfile) -> [String] {
        reasons(job, for: profile).map(\.label)
    }

    // this is how the jobs get their scores
    private static func reasons(_ job: Job, for profile: UserProfile) -> [(label: String, weight: Int)] {
        var result: [(String, Int)] = []

        if let title = profile.jobTitles.first(where: { titleMatches(job.title, $0) }) {
            result.append((title, titleWeight))
        }
        if profile.jobTypes.contains(job.jobType.rawValue) {
            result.append((job.jobType.rawValue, jobTypeWeight))
        }
        if profile.workSettings.contains(job.workMode.rawValue) {
            result.append((job.workMode.rawValue, workSettingWeight))
        }
        if let city = profile.locations.first(where: { locationMatches(job.location, $0) }) {
            result.append((city, locationWeight))
        }
        if profile.experienceLevels.contains(job.experienceLevel.rawValue) {
            result.append((job.experienceLevel.rawValue, experienceWeight))
        }
        return result
    }

    // matches the titles
    private static func titleMatches(_ jobTitle: String, _ picked: String) -> Bool {
        normalize(jobTitle).contains(normalize(picked))
    }

    /// matches the lo
    private static func locationMatches(_ jobLocation: String, _ city: String) -> Bool {
        let jobCity = jobLocation.split(separator: ",").first.map(String.init) ?? jobLocation
        return normalize(jobCity) == normalize(city) || normalize(jobLocation) == normalize(city)
    }

    /// Lowercase and strip everything 
    private static func normalize(_ text: String) -> String {
        text.lowercased().filter { $0.isLetter || $0.isNumber }
    }
}
