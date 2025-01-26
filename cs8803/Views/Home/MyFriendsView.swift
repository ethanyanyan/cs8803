import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MyFriendsView: View {
    @State private var acceptedFriends: [UserProfile] = []
    @State private var pendingRequests: [UserProfile] = []
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

                List {
                    // Section for Pending Friend Requests
                    if !pendingRequests.isEmpty {
                        Section(header: Text("Pending Requests")) {
                            ForEach(pendingRequests) { user in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(user.displayName)
                                            .font(.headline)
                                        Text(user.email)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Button("Accept") {
                                        acceptFriendRequest(from: user.id)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    .foregroundColor(.green)

                                    Button("Reject") {
                                        removeFriend(userID: user.id)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    .foregroundColor(.red)
                                }
                            }
                        }
                    }

                    // Section for Accepted Friends
                    if !acceptedFriends.isEmpty {
                        Section(header: Text("My Friends")) {
                            ForEach(acceptedFriends) { friend in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(friend.displayName)
                                            .font(.headline)
                                        Text(friend.email)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Button("Remove") {
                                        removeFriend(userID: friend.id)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("My Friends")
            }
        }
        .onAppear {
            fetchFriends()
        }
    }

    // Fetch both accepted friends and pending requests
    private func fetchFriends() {
        guard let currentUID = currentUID else { return }

        db.collection("users").document(currentUID).collection("friends")
            .getDocuments { snapshot, error in
                if let error = error {
                    statusMessage = "Error fetching friends: \(error.localizedDescription)"
                    return
                }

                var tempAccepted: [UserProfile] = []
                var tempPending: [UserProfile] = []

                snapshot?.documents.forEach { doc in
                    let data = doc.data()
                    let uid = doc.documentID
                    let displayName = data["displayName"] as? String ?? "(No Name)"
                    let email = data["email"] as? String ?? "(No Email)"
                    let status = data["status"] as? String ?? ""

                    let userProfile = UserProfile(id: uid, displayName: displayName, email: email)

                    if status == "accepted" {
                        tempAccepted.append(userProfile)
                    } else if status == "pending" {
                        tempPending.append(userProfile)
                    }
                }

                self.acceptedFriends = tempAccepted
                self.pendingRequests = tempPending
            }
    }

    // Accept friend request
    private func acceptFriendRequest(from userID: String) {
        friendService.acceptFriendRequest(from: userID) { error in
            if let error = error {
                self.statusMessage = "Error accepting request: \(error.localizedDescription)"
            } else {
                self.statusMessage = "Friend request accepted!"
                self.pendingRequests.removeAll { $0.id == userID }
                fetchFriends()
            }
        }
    }

    // Remove or reject friend
    private func removeFriend(userID: String) {
        friendService.removeFriend(userID: userID) { error in
            if let error = error {
                self.statusMessage = "Error removing friend: \(error.localizedDescription)"
            } else {
                self.statusMessage = "Friend removed successfully!"
                self.acceptedFriends.removeAll { $0.id == userID }
                self.pendingRequests.removeAll { $0.id == userID }
            }
        }
    }
}

#Preview {
    MyFriendsView()
}
