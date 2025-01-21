//
//  FriendsView.swift
//  cs8803
//
//  Created by Ethan Yan on 21/1/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FriendsView: View {
    @State private var allUsers: [UserProfile] = []
    @State private var friendStatuses: [String: String] = [:]   // Map userId -> "pending"/"accepted"/nil
    @State private var requestSenders: [String: String] = [:]   // Map userId -> requestSender
    @State private var statusMessage: String?

    private let friendService = FriendshipService()
    private let db = Firestore.firestore()

    private var currentUID: String? {
        Auth.auth().currentUser?.uid
    }

    var body: some View {
        NavigationView {
            VStack {
                if let msg = statusMessage {
                    Text(msg)
                        .foregroundColor(.blue)
                        .padding(.bottom)
                }

                List(allUsers) { user in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.displayName)
                            .font(.headline)
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        // Show the current friendship status
                        let status = friendStatuses[user.id] ?? "none"
                        Text("Status: \(status)")
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        // Buttons row
                        HStack {
                            switch status {
                            case "pending":
                                // If current user is the request sender, just show "Request sent"
                                if requestSenders[user.id] == currentUID {
                                    Text("Request sent")
                                        .foregroundColor(.gray)
                                } else {
                                    // The other user is requestSender => current user can accept or reject
                                    Button("Accept") {
                                        acceptFriendRequest(from: user.id)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())

                                    Button("Reject") {
                                        removeFriend(userID: user.id)
                                    }
                                    .foregroundColor(.red)
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                            case "accepted":
                                Button("Remove Friend") {
                                    removeFriend(userID: user.id)
                                }
                                .foregroundColor(.red)
                                .buttonStyle(BorderlessButtonStyle())
                            default:
                                // No doc or "none" => Add friend
                                Button("Add Friend") {
                                    sendFriendRequest(to: user.id)
                                }
                                .foregroundColor(.blue)
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .navigationTitle("Friends")
            }
        }
        .onAppear {
            fetchAllUsers()
            fetchMyFriendDocs()
        }
    }

    // MARK: - Fetch All Users
    private func fetchAllUsers() {
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                statusMessage = "Error fetching all users: \(error.localizedDescription)"
                return
            }
            var temp: [UserProfile] = []
            snapshot?.documents.forEach { doc in
                let data = doc.data()
                let uid = doc.documentID
                let displayName = data["displayName"] as? String ?? "(No Name)"
                let email = data["email"] as? String ?? "(No Email)"
                
                // Optionally skip the current user in this list
                if uid != currentUID {
                    temp.append(UserProfile(id: uid, displayName: displayName, email: email))
                }
            }
            self.allUsers = temp
        }
    }

    // MARK: - Fetch Friend Docs For Current User
    private func fetchMyFriendDocs() {
        guard let currentUID = currentUID else { return }

        db.collection("users")
          .document(currentUID)
          .collection("friends")
          .addSnapshotListener { snapshot, error in
            if let error = error {
                self.statusMessage = "Error fetching friends: \(error.localizedDescription)"
                return
            }

            // Clear old data each time
            var newStatuses: [String: String] = [:]
            var newRequestSenders: [String: String] = [:]

            snapshot?.documents.forEach { doc in
                // doc.documentID => friendId
                let friendId = doc.documentID
                let data = doc.data()
                let status = data["status"] as? String ?? "none"
                let requestSender = data["requestSender"] as? String ?? ""

                newStatuses[friendId] = status
                newRequestSenders[friendId] = requestSender
            }

            // Update local state
            self.friendStatuses = newStatuses
            self.requestSenders = newRequestSenders
        }
    }

    // MARK: - Send Friend Request
    private func sendFriendRequest(to userID: String) {
        friendService.sendFriendRequest(to: userID) { error in
            if let error = error {
                self.statusMessage = "Error sending request: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Accept Friend Request
    private func acceptFriendRequest(from userID: String) {
        friendService.acceptFriendRequest(from: userID) { error in
            if let error = error {
                self.statusMessage = "Error accepting request: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Remove Friend
    private func removeFriend(userID: String) {
        friendService.removeFriend(userID: userID) { error in
            if let error = error {
                self.statusMessage = "Error removing friend: \(error.localizedDescription)"
            }
        }
    }
}
