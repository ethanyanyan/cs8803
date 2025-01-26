//
//  ExploreFirendsView.swift
//  cs8803
//
//  Created by Yeongbin Kim on 1/25/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ExploreFriendsView: View {
    @State private var exploreUsers: [UserProfile] = []
    @State private var statusMessage: String?

    private let friendService = FriendshipService()
    private let db = Firestore.firestore()
    
    private var currentUID: String? {
        Auth.auth().currentUser?.uid
    }

    var body: some View {
        VStack {
            if let msg = statusMessage {
                Text(msg)
                    .foregroundColor(.blue)
                    .padding(.bottom)
            }

            List(exploreUsers) { user in
                VStack(alignment: .leading) {
                    Text(user.displayName)
                        .font(.headline)
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Button("Add Friend") {
                        sendFriendRequest(to: user.id)
                    }
                    .foregroundColor(.blue)
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .navigationTitle("Explore Friends")
        }
        .onAppear {
            fetchExploreUsers()
        }
    }

    // MARK: - Fetch Users to Explore
    private func fetchExploreUsers() {
        guard let currentUID = currentUID else { return }

        // Step 1: Fetch all users
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                statusMessage = "Error fetching users: \(error.localizedDescription)"
                return
            }

            var allUsers: [UserProfile] = snapshot?.documents.compactMap { doc in
                let data = doc.data()
                let uid = doc.documentID
                let displayName = data["displayName"] as? String ?? "(No Name)"
                let email = data["email"] as? String ?? "(No Email)"
                
                return UserProfile(id: uid, displayName: displayName, email: email)
            } ?? []

            // Step 2: Remove the current user from the list
            allUsers.removeAll { $0.id == currentUID }

            // Step 3: Fetch the current user's friend list (including pending requests)
            db.collection("users")
                .document(currentUID)
                .collection("friends")
                .getDocuments { snapshot, error in
                    if let error = error {
                        statusMessage = "Error fetching friends: \(error.localizedDescription)"
                        return
                    }

                    let friendIDs = snapshot?.documents.map { $0.documentID } ?? []
                    
                    // Step 4: Remove users who are already friends or have pending requests
                    allUsers.removeAll { friendIDs.contains($0.id) }

                    // Step 5: Update state
                    self.exploreUsers = allUsers
                }
        }
    }

    // MARK: - Send Friend Request
    private func sendFriendRequest(to userID: String) {
        friendService.sendFriendRequest(to: userID) { error in
            if let error = error {
                self.statusMessage = "Error sending request: \(error.localizedDescription)"
            } else {
                self.statusMessage = "Friend request sent!"
                // Refresh explore users to remove the user from the list
                fetchExploreUsers()
            }
        }
    }
}
