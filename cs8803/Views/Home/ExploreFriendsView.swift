//
//  ExploreFriendsView.swift
//  cs8803
//
//  Created by Yeongbin Kim on 1/25/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ExploreFriendsView: View {
    @State private var allUsers: [UserProfile] = []
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
                        .foregroundColor(.red)
                        .padding()
                }
                
                List(allUsers) { user in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(user.displayName)
                                .font(.headline)
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Button("Add Friend") {
                            sendFriendRequest(to: user.id)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .foregroundColor(.blue)
                    }
                }
                .navigationTitle("Explore Friends")
            }
        }
        .onAppear {
            fetchUsers()
        }
    }
    
    private func fetchUsers() {
        guard let currentUID = currentUID else { return }
        
        // Step 1: Fetch current user's friends (both accepted & pending)
        db.collection("users").document(currentUID).collection("friends")
            .getDocuments { friendSnapshot, error in
                if let error = error {
                    statusMessage = "Error fetching friends: \(error.localizedDescription)"
                    return
                }

                var excludedUserIDs: Set<String> = [currentUID] // Always exclude self
                
                // Add all accepted and pending friends to exclusion list
                friendSnapshot?.documents.forEach { doc in
                    excludedUserIDs.insert(doc.documentID)
                }
                
                // Step 2: Fetch all users and filter out those already in friends list
                db.collection("users").getDocuments { snapshot, error in
                    if let error = error {
                        statusMessage = "Error fetching users: \(error.localizedDescription)"
                        return
                    }
                    
                    var tempUsers: [UserProfile] = []
                    snapshot?.documents.forEach { doc in
                        let data = doc.data()
                        let uid = doc.documentID
                        let displayName = data["displayName"] as? String ?? "(No Name)"
                        let email = data["email"] as? String ?? "(No Email)"

                        if !excludedUserIDs.contains(uid) {
                            tempUsers.append(UserProfile(id: uid, displayName: displayName, email: email))
                        }
                    }
                    
                    self.allUsers = tempUsers
                }
            }
    }
    
    private func sendFriendRequest(to userID: String) {
        friendService.sendFriendRequest(to: userID) { error in
            if let error = error {
                self.statusMessage = "Error sending request: \(error.localizedDescription)"
            } else {
                self.statusMessage = "Friend request sent!"
            }
        }
    }
}

#Preview {
    ExploreFriendsView()
}
