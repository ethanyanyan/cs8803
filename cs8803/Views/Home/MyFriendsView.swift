//
//  MyFriendsView.swift
//  cs8803
//
//  Created by Yeongbin Kim on 1/25/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MyFriendsView: View {
    @State private var friends: [UserProfile] = []
    @State private var friendStatuses: [String: String] = [:]   // Map userId -> "pending"/"accepted"
    @State private var requestSenders: [String: String] = [:]   // Map userId -> requestSender
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

            List(friends) { user in
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName)
                        .font(.headline)
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    // Show the current friendship status
                    let status = friendStatuses[user.id] ?? "none"
                    Text("Status: \(status.capitalized)")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    // Action Buttons
                    HStack {
                        if status == "pending" {
                            // If the current user is NOT the request sender, they can accept/reject
                            if requestSenders[user.id] != currentUID {
                                Button("Accept") {
                                    acceptFriendRequest(from: user.id)
                                }
                                .buttonStyle(BorderlessButtonStyle())

                                Button("Reject") {
                                    removeFriend(userID: user.id)
                                }
                                .foregroundColor(.red)
                                .buttonStyle(BorderlessButtonStyle())
                            } else {
                                Text("Request Sent")
                                    .foregroundColor(.gray)
                            }
                        } else if status == "accepted" {
                            Button("Remove Friend") {
                                removeFriend(userID: user.id)
                            }
                            .foregroundColor(.red)
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                }
            }
            .navigationTitle("My Friends")
        }
        .onAppear {
            fetchFriends()
        }
    }

    // MARK: - Fetch Friends & Requests
    private func fetchFriends() {
        guard let currentUID = currentUID else { return }

        db.collection("users").document(currentUID).collection("friends")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    self.statusMessage = "Error fetching friends: \(error.localizedDescription)"
                    return
                }

                var tempFriends: [UserProfile] = []
                var newStatuses: [String: String] = [:]
                var newRequestSenders: [String: String] = [:]

                snapshot?.documents.forEach { doc in
                    let friendId = doc.documentID
                    let data = doc.data()
                    let status = data["status"] as? String ?? "none"
                    let requestSender = data["requestSender"] as? String ?? ""

                    newStatuses[friendId] = status
                    newRequestSenders[friendId] = requestSender

                    // Fetch user details from Firestore
                    db.collection("users").document(friendId).getDocument { document, error in
                        if let error = error {
                            print("Error fetching user details: \(error.localizedDescription)")
                            return
                        }

                        if let document = document, document.exists {
                            let userData = document.data() ?? [:]
                            let displayName = userData["displayName"] as? String ?? "(No Name)"
                            let email = userData["email"] as? String ?? "(No Email)"
                            let user = UserProfile(id: friendId, displayName: displayName, email: email)

                            DispatchQueue.main.async {
                                tempFriends.append(user)
                                self.friends = tempFriends
                                self.friendStatuses = newStatuses
                                self.requestSenders = newRequestSenders
                            }
                        }
                    }
                }
            }
    }

    // MARK: - Accept Friend Request
    private func acceptFriendRequest(from userID: String) {
        friendService.acceptFriendRequest(from: userID) { error in
            if let error = error {
                self.statusMessage = "Error accepting request: \(error.localizedDescription)"
            } else {
                self.statusMessage = "Friend request accepted!"
                fetchFriends()
            }
        }
    }

    // MARK: - Remove Friend
    private func removeFriend(userID: String) {
        friendService.removeFriend(userID: userID) { error in
            if let error = error {
                self.statusMessage = "Error removing friend: \(error.localizedDescription)"
            } else {
                self.statusMessage = "Friend removed."
                fetchFriends()
            }
        }
    }
}
