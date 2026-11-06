import Foundation

/// Everything we store about a user in Firestore at users/{uid}.
struct UserProfile: Equatable {
    var username = ""
    var email = ""

    // Preferences
    var jobTitles: [String] = []
    var jobTypes: [String] = []
    var experienceLevels: [String] = []
    var locations: [String] = []
    var workSettings: [String] = []      // In-Person / Remote / Hybrid

    // Demographics (nil = skipped)
    var veteranStatus: String?
    var disabilityStatus: String?
    var workAuthorized: String?
    var requiresSponsorship: String?

    var notificationsEnabled: Bool?
    var onboardingComplete = false

    init(username: String = "", email: String = "") {
        self.username = username
        self.email = email
    }

    /// Build from a Firestore document
    init(data: [String: Any]) {
        username = data["username"] as? String ?? ""
        email = data["email"] as? String ?? ""
        onboardingComplete = data["onboardingComplete"] as? Bool ?? false
        notificationsEnabled = data["notificationsEnabled"] as? Bool

        let prefs = data["preferences"] as? [String: Any] ?? [:]
        jobTitles = prefs["jobTitles"] as? [String] ?? []
        jobTypes = prefs["jobTypes"] as? [String] ?? []
        experienceLevels = prefs["experienceLevels"] as? [String] ?? []
        locations = prefs["locations"] as? [String] ?? []
        workSettings = prefs["workSettings"] as? [String] ?? []

        let demo = data["demographics"] as? [String: Any] ?? [:]
        veteranStatus = demo["veteranStatus"] as? String
        disabilityStatus = demo["disabilityStatus"] as? String
        workAuthorized = demo["workAuthorized"] as? String
        requiresSponsorship = demo["requiresSponsorship"] as? String
    }

    /// Shape written to Firestore
    var firestoreData: [String: Any] {
        let preferences: [String: Any] = [
            "jobTitles": jobTitles,
            "jobTypes": jobTypes,
            "experienceLevels": experienceLevels,
            "locations": locations,
            "workSettings": workSettings,
        ]
        let demographics: [String: Any] = [
            "veteranStatus": Self.orNull(veteranStatus),
            "disabilityStatus": Self.orNull(disabilityStatus),
            "workAuthorized": Self.orNull(workAuthorized),
            "requiresSponsorship": Self.orNull(requiresSponsorship),
        ]
        var data: [String: Any] = [
            "username": username,
            "email": email,
            "onboardingComplete": onboardingComplete,
            "preferences": preferences,
            "demographics": demographics,
        ]
        if let notificationsEnabled { data["notificationsEnabled"] = notificationsEnabled }
        return data
    }

    private static func orNull(_ value: String?) -> Any {
        if let value { return value }
        return NSNull()
    }
}
