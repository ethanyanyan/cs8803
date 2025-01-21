//
//  ProfileView.swift
//  cs8803
//
//  Created by Ethan Yan on 19/1/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import PhotosUI
import CoreLocation
import Cloudinary

struct ProfileView: View {
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var location: String = ""
    @State private var avatarURL: URL?
    
    // For picking avatar
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
    // For status messages or errors
    @State private var statusMessage: String?
    
    // For showing alerts
    @State private var showingLocationAlert = false
    
    // Observe custom LocationManager
    @StateObject private var locationManager = LocationManager()
    
    // Firestore reference
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                
                // Avatar with pick button
                if let avatarURL = avatarURL {
                    AsyncImage(url: avatarURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        case .failure(_):
                            Image(systemName: "person.crop.circle.badge.xmark")
                                .resizable()
                                .frame(width: 100, height: 100)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    // Placeholder avatar
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 100, height: 100)
                }
                
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Text("Change Avatar")
                        .foregroundColor(.blue)
                }
                .onChange(of: selectedItem) { newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                            selectedImageData = data
                            // Upload to Cloudinary
                            uploadAvatarToCloudinary(data: data)
                        }
                    }
                }
                
                // User info fields
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email (read-only)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Email", text: $email)
                        .disabled(true)
                        .opacity(0.7)
                    
                    Text("Display Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Display Name", text: $displayName)
                    
                    Text("Location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Location", text: $location)
                    
                    Button("Use Current Location") {
                        locationManager.requestPermission()
                    }
                    .padding(.top, 8)
                    
                    // Optional: Show location status
                    if let status = locationManager.status {
                        Text("Location status: \(statusString(for: status))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                
                Button("Save Profile") {
                    saveProfile()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                // Show status or error
                if let statusMessage = statusMessage {
                    Text(statusMessage)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                // Sign out button
                Button("Sign Out") {
                    do {
                        try Auth.auth().signOut()
                    } catch {
                        print("Sign out error: \(error.localizedDescription)")
                    }
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.top, 20)
            .navigationTitle("Profile")
            .alert(isPresented: $showingLocationAlert) {
                Alert(
                    title: Text("Location Access Denied"),
                    message: Text("Please enable location services for this app in Settings."),
                    primaryButton: .default(Text("Open Settings")) {
                        openAppSettings()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        // On appear, load profile from Firestore
        .onAppear {
            loadProfile()
        }
        // If userLocation changes, reverse geocode to get city, state, etc.
        .onChange(of: locationManager.userLocation) { newLocation in
            guard let loc = newLocation else { return }
            reverseGeocode(location: loc)
        }
        // Handle location authorization changes
        .onChange(of: locationManager.status) { newStatus in
            if newStatus == .denied || newStatus == .restricted {
                showingLocationAlert = true
            }
        }
    }
    
    // MARK: - Load Profile
    private func loadProfile() {
        guard let user = Auth.auth().currentUser else {
            statusMessage = "User not found. Please log in or sign up."
            return
        }
        
        // Set email from Auth (read-only)
        email = user.email ?? ""
        
        // Read from Firestore
        let userRef = db.collection("users").document(user.uid)
        userRef.getDocument { document, error in
            if let error = error {
                statusMessage = "Error loading profile: \(error.localizedDescription)"
                return
            }
            if let document = document, document.exists {
                let data = document.data() ?? [:]
                self.displayName = data["displayName"] as? String ?? ""
                self.location = data["location"] as? String ?? ""
                
                if let avatarString = data["avatarURL"] as? String,
                   let url = URL(string: avatarString) {
                    self.avatarURL = url
                }
            }
        }
    }
    
    // MARK: - Upload Avatar (Cloudinary)
    private func uploadAvatarToCloudinary(data: Data) {
        guard let user = Auth.auth().currentUser else { return }
        
        let cloudName = "dcvqrt5p0"
        let uploadPreset = "ios_unsigned_preset"
        
        let config = CLDConfiguration(cloudName: cloudName, secure: true)
        let cloudinary = CLDCloudinary(configuration: config)
        
        let params = CLDUploadRequestParams()
        params.setUploadPreset(uploadPreset)
        params.setPublicId("avatars-\(user.uid)")
        
        let uploadRequest = cloudinary.createUploader().upload(
            data: data,
            uploadPreset: uploadPreset,
            params: params
        )
        
        uploadRequest.response { (result, error) in
            if let error = error {
                self.statusMessage = "Cloudinary upload error: \(error.localizedDescription)"
                print("Cloudinary error: \(error)")
                return
            }
            guard let result = result,
                  let secureUrl = result.secureUrl else {
                self.statusMessage = "No secure URL returned from Cloudinary."
                return
            }
            
            self.avatarURL = URL(string: secureUrl)
            let db = Firestore.firestore()
            db.collection("users").document(user.uid).setData(["avatarURL": secureUrl],
                                                              merge: true) { err in
                if let err = err {
                    self.statusMessage = "Error saving Cloudinary URL: \(err.localizedDescription)"
                } else {
                    self.statusMessage = "Avatar updated!"
                }
            }
        }
        .progress { progress in
            let uploaded = progress.completedUnitCount
            let total = progress.totalUnitCount
            print("Cloudinary upload progress: \(uploaded) / \(total)")
        }
    }
    
    // MARK: - Save Profile
    private func saveProfile() {
        guard let user = Auth.auth().currentUser else { return }
        
        let userData: [String: Any] = [
            "displayName": displayName,
            "location": location,
            "email": email
            // "avatarURL" is set in uploadAvatarToCloudinary
        ]
        
        db.collection("users").document(user.uid).setData(userData, merge: true) { error in
            if let error = error {
                statusMessage = "Error saving profile: \(error.localizedDescription)"
            } else {
                statusMessage = "Profile updated"
            }
        }
    }
    
    // MARK: - Reverse Geocode
    private func reverseGeocode(location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocode error: \(error.localizedDescription)")
                statusMessage = "Unable to retrieve location details."
                return
            }
            if let placemark = placemarks?.first {
                let city = placemark.locality ?? ""
                let state = placemark.administrativeArea ?? ""
                let country = placemark.country ?? ""
                
                self.location = [city, state, country]
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")
            }
        }
    }
    
    // MARK: - Helper to Convert CLAuthorizationStatus to String
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
    
    // MARK: - Open App Settings
    private func openAppSettings() {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(appSettings) {
                UIApplication.shared.open(appSettings)
            }
        }
    }
}
