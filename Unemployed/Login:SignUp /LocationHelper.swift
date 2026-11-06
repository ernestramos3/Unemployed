import Foundation
import CoreLocation

/// Gets location from the user (helps narrow the locations when putting in that info)
@MainActor
final class LocationHelper: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var city: String?
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestCity() {
        guard !AuthViewModel.isRunningInPreview else { return }
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()   // shows the iOS permission prompt
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break                                     // denied: user types locations instead
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = self.manager.authorizationStatus
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.manager.requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            let placemarks = try? await CLGeocoder().reverseGeocodeLocation(location)
            if let city = placemarks?.first?.locality {
                self.city = city
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("⚠️ Location error:", error.localizedDescription)
    }
}
