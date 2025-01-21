//
//  ProfileView.swift
//  cs8803
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI
import CoreLocation

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

    // Observe custom LocationManager
    @StateObject private var locationManager = LocationManager()

    // Firestore references
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

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
                            uploadAvatar(data: data)
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

    // MARK: - Upload Avatar
    private func uploadAvatar(data: Data) {
        guard let user = Auth.auth().currentUser else { return }

        let storageRef = storage.reference().child("avatars/\(user.uid).jpg")
        storageRef.putData(data, metadata: nil) { _, error in
            if let error = error {
                statusMessage = "Error uploading avatar: \(error.localizedDescription)"
                return
            }
            // Get download URL
            storageRef.downloadURL { url, error in
                if let error = error {
                    statusMessage = "Error retrieving avatar URL: \(error.localizedDescription)"
                    return
                }
                if let url = url {
                    self.avatarURL = url
                    // Save to Firestore
                    self.db.collection("users").document(user.uid).setData(["avatarURL": url.absoluteString],
                                                                          merge: true)
                    statusMessage = "Avatar updated"
                }
            }
        }
    }

    // MARK: - Save Profile
    private func saveProfile() {
        guard let user = Auth.auth().currentUser else { return }

        let userData: [String: Any] = [
            "displayName": displayName,
            "location": location,
            "email": email
            // "avatarURL" is set in uploadAvatar
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
                return
            }
            if let placemark = placemarks?.first {
                // For example, city + state/country
                let city = placemark.locality ?? ""
                let state = placemark.administrativeArea ?? ""
                let country = placemark.country ?? ""
                
                // Combine how you'd like
                self.location = [city, state, country]
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")
            }
        }
    }
}
