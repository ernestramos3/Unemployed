import Foundation

enum Catalog {
    static let jobTypes = ["Full-Time", "Contract", "Part-Time", "Internship"]
    static let experienceLevels = ["Entry-Level", "Mid-Level", "Senior", "Executive"]
    static let workSettings = ["In-Person", "Remote", "Hybrid"]

    static let veteranOptions = ["Yes, I am a Veteran", "No, I am not a veteran", "Prefer Not to Say"]
    static let disabilityOptions = ["Yes, I have a disability", "No, I do not have a disability", "Prefer Not to Say"]
    static let yesNoOptions = ["Yes", "No", "Prefer Not to Say"]

    static let jobTitles = [
        "UX Designer", "UX Researcher", "UX Writer", "UI Designer", "User Researcher",
        "Product Designer", "Design Engineer", "Systems Designer", "Graphic Designer",
        "Motion Designer", "Visual Designer", "Interaction Designer",
        "Software Engineer", "iOS Developer", "Android Developer", "Frontend Developer",
        "Backend Developer", "Full Stack Developer", "Mobile Developer", "Web Developer",
        "Data Analyst", "Data Scientist", "Data Engineer", "Machine Learning Engineer",
        "DevOps Engineer", "QA Engineer", "Security Analyst", "IT Support Specialist",
        "Product Manager", "Project Manager", "Program Manager", "Business Analyst",
        "Marketing Coordinator", "Marketing Analyst", "Social Media Manager",
        "Content Writer", "Copywriter", "Sales Associate", "Account Executive",
        "Financial Analyst", "Accountant", "Consultant", "Operations Analyst",
        "HR Coordinator", "Recruiter", "Customer Success Manager", "Research Assistant",
    ]

    static let cities = [
        "Austin", "Allen", "Atlanta", "Dallas", "Fort Worth", "Houston", "San Antonio",
        "Plano", "Round Rock", "El Paso", "Frisco", "Irving", "Arlington",
        "Boston", "Charlotte", "Chicago", "Denver", "Detroit", "Los Angeles", "Miami",
        "Minneapolis", "Nashville", "New York", "Philadelphia", "Phoenix", "Portland",
        "Raleigh", "Salt Lake City", "San Diego", "San Francisco", "San Jose",
        "Seattle", "Washington, D.C.",
    ]

    static func similarTitles(to picked: [String], limit: Int = 4) -> [String] {
        guard !picked.isEmpty else { return [] }
        let words = Set(picked.flatMap { $0.lowercased().split(separator: " ").map(String.init) })
        return jobTitles
            .filter { !picked.contains($0) }
            .filter { title in title.lowercased().split(separator: " ").contains { words.contains(String($0)) } }
            .prefix(limit)
            .map { $0 }
    }
}
