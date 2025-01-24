//
//  FeedView.swift
//  cs8803
//
//  Created by Ethan Yan on 19/1/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FeedView: View {
    @State private var posts: [Post] = []
    @State private var userNames: [String: String] = [:] // Map userId to displayName
    @State private var statusMessage: String?

    private let db = Firestore.firestore()
    private var currentUID: String? {
        Auth.auth().currentUser?.uid
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    if posts.isEmpty {
                        Text("No posts to display.")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ForEach(posts) { post in
                            VStack(alignment: .leading, spacing: 8) {
                                // Display poster name
                                if let posterName = userNames[post.userId] {
                                    Text(posterName)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                } else {
                                    Text("Unknown User")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                }

                                // Display post image
                                AsyncImage(url: URL(string: post.imageURL)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .cornerRadius(8)
                                    case .failure(_):
                                        Image(systemName: "photo.fill")
                                            .resizable()
                                            .frame(maxWidth: 300, maxHeight: 200)
                                            .foregroundColor(.gray)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }

                                // Display caption
                                Text(post.caption)
                                    .font(.body)
                                    .foregroundColor(.primary)

                                // Display timestamp
                                Text(post.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                    }

                    if let statusMessage = statusMessage {
                        Text(statusMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
            }
            .navigationTitle("Feed")
            .onAppear {
                fetchFeedPosts()
            }
        }
    }

    private func fetchFeedPosts() {
        guard let currentUID = currentUID else { return }

        // Step 1: Fetch the user's accepted friends
        db.collection("users").document(currentUID).collection("friends")
            .whereField("status", isEqualTo: "accepted")
            .getDocuments { snapshot, error in
                if let error = error {
                    statusMessage = "Error fetching friends: \(error.localizedDescription)"
                    return
                }

                // Get the list of friend UIDs
                var friendIds = snapshot?.documents.map { $0.documentID } ?? []
                friendIds.append(currentUID) // Include the current user

                // Step 2: Fetch posts from these UIDs
                db.collection("posts")
                    .whereField("userId", in: friendIds)
                    .order(by: "timestamp", descending: true)
                    .getDocuments { snapshot, error in
                        if let error = error {
                            statusMessage = "Error fetching posts: \(error.localizedDescription)"
                            return
                        }

                        posts = snapshot?.documents.compactMap { doc in
                            let data = doc.data()
                            return Post(
                                id: doc.documentID,
                                userId: data["userId"] as? String ?? "",
                                caption: data["caption"] as? String ?? "",
                                imageURL: data["imageURL"] as? String ?? "",
                                timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                            )
                        } ?? []

                        // Step 3: Fetch display names for all unique userIds
                        let userIds = Set(posts.map { $0.userId })
                        fetchUserNames(for: Array(userIds))
                    }
            }
    }

    private func fetchUserNames(for userIds: [String]) {
        let userRefs = userIds.map { db.collection("users").document($0) }

        for ref in userRefs {
            ref.getDocument { document, error in
                if let error = error {
                    print("Error fetching user name: \(error.localizedDescription)")
                    return
                }

                if let document = document, document.exists {
                    let data = document.data() ?? [:]
                    let displayName = data["displayName"] as? String ?? "Unknown User"
                    self.userNames[document.documentID] = displayName
                }
            }
        }
    }
}

struct Post: Identifiable {
    let id: String
    let userId: String
    let caption: String
    let imageURL: String
    let timestamp: Date
}
