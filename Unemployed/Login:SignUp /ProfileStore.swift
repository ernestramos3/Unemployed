import Foundation
import FirebaseFirestore

/// All Firestore reads and writes. via uid
enum ProfileStore {
    private static func document(_ uid: String) -> DocumentReference {
        Firestore.firestore().collection("users").document(uid)
    }

    /// Called right after sign up
    static func createUser(uid: String, username: String, email: String) async throws {
        try await document(uid).setData([
            "username": username,
            "email": email,
            "onboardingComplete": false,
            "createdAt": FieldValue.serverTimestamp(),
        ], merge: true)
    }

    static func load(uid: String) async throws -> UserProfile? {
        let snapshot = try await document(uid).getDocument()
        guard let data = snapshot.data() else { return nil }
        return UserProfile(data: data)
    }

    /// Saves the whole profile (merging, so createdAt is kept)
    static func save(_ profile: UserProfile, uid: String) async throws {
        var data = profile.firestoreData
        data["updatedAt"] = FieldValue.serverTimestamp()
        try await document(uid).setData(data, merge: true)
    }

    // errors for the firestore
    static func message(for error: Error) -> String {
        switch (error as NSError).code {
        case 7:  return "Firestore Blocked the Save. Check Your Security Rules"
        case 5:  return "Firestore Database Not Found. Create It in the Console"
        case 14: return "Network Error. Check Your Connection"
        default: return "Couldn't Save Your Answers. Please Try Again"
        }
    }
}
