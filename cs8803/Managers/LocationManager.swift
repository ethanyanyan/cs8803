//
//  LocationManager.swift
//  cs8803
//
//  Created by Ethan Yan on 21/1/25.
//

import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var userLocation: CLLocation?
    @Published var status: CLAuthorizationStatus?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestPermission() {
        let currentStatus = manager.authorizationStatus
        print("Current authorization status: \(currentStatus.rawValue) - \(statusString(for: currentStatus))")
        switch currentStatus {
        case .notDetermined:
            print("Requesting When In Use authorization")
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            print("Already authorized")
            manager.startUpdatingLocation()
        case .denied, .restricted:
            print("Access denied or restricted")
            // Notify user to enable location services
            DispatchQueue.main.async {
                self.status = currentStatus
            }
        @unknown default:
            print("Unknown authorization status")
        }
    }
    
    // CLLocationManagerDelegate method
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Authorization status changed to: \(status.rawValue) - \(statusString(for: status))")
        DispatchQueue.main.async {
            self.status = status
        }
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("Starting location updates")
            manager.startUpdatingLocation()
        case .denied, .restricted:
            print("Stopping location updates due to denied/restricted status")
            manager.stopUpdatingLocation()
            // Reset userLocation
            DispatchQueue.main.async {
                self.userLocation = nil
            }
        case .notDetermined:
            print("Authorization status not determined")
        @unknown default:
            print("Unknown authorization status")
        }
    }
    
    // CLLocationManagerDelegate method
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            print("No locations found in didUpdateLocations")
            return
        }
        print("Received location update: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        DispatchQueue.main.async {
            self.userLocation = location
        }
    }
    
    // Handle location errors
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager failed with error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            // Optionally, reset userLocation or update status
            self.userLocation = nil
            self.status = manager.authorizationStatus
        }
    }
    
    // Helper to convert CLAuthorizationStatus to String
    private func statusString(for status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorizedWhenInUse:
            return "Authorized When In Use"
        case .authorizedAlways:
            return "Authorized Always"
        @unknown default:
            return "Unknown"
        }
    }
}
