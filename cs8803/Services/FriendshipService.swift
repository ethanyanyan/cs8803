//
//  FriendshipService.swift
//  cs8803
//
//  Created by Ethan Yan on 21/1/25.
//


import FirebaseFirestore
import FirebaseAuth

class FriendshipService {
    private let db = Firestore.firestore()

    // MARK: - Send Friend Request
    func sendFriendRequest(to userB: String, completion: @escaping (Error?) -> Void) {
        guard let userA = Auth.auth().currentUser?.uid else { return }

        let userADocRef = db.collection("users").document(userA)
        let userBDocRef = db.collection("users").document(userB)

        // References for each subcollection doc
        let docRefInB = userBDocRef.collection("friends").document(userA)
        let docRefInA = userADocRef.collection("friends").document(userB)

        db.runTransaction({ transaction, errorPointer in
            // 1) Create or update doc in B’s subcollection => pending
            transaction.setData([
                "status": "pending",
                "requestSender": userA,
                "lastUpdated": FieldValue.serverTimestamp()
            ], forDocument: docRefInB, merge: true)

            return nil
        }) { (_, error) in
            completion(error)
        }
    }

    
    // MARK: - Accept Friend Request
    func acceptFriendRequest(from userA: String, completion: @escaping (Error?) -> Void) {
        guard let userB = Auth.auth().currentUser?.uid else { return }

        let userBDocRef = db.collection("users").document(userB)
        let userADocRef = db.collection("users").document(userA)
        
        // 1) Update B's record about A => accepted
        let docRefB = userBDocRef.collection("friends").document(userA)
        // 2) Also create A's record about B => accepted
        let docRefA = userADocRef.collection("friends").document(userB)
        
        db.runTransaction({ transaction, errorPointer in
            // B's doc => accepted
            transaction.setData([
                "status": "accepted",
                "lastUpdated": FieldValue.serverTimestamp()
            ], forDocument: docRefB, merge: true)
            
            // A's doc => accepted
            transaction.setData([
                "status": "accepted",
                "lastUpdated": FieldValue.serverTimestamp()
            ], forDocument: docRefA, merge: true)
            
            return nil
        }) { (_, error) in
            completion(error)
        }
    }
    
    // MARK: - Reject or Remove Friend
    func removeFriend(userID: String, completion: @escaping (Error?) -> Void) {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }

        let docRef = db.collection("users")
            .document(currentUID)
            .collection("friends")
            .document(userID)
        
        docRef.delete { error in
            completion(error)
        }
    }
    
    // MARK: - Fetch My Friends (Accepted)
    func fetchAcceptedFriends(completion: @escaping ([UserProfile]) -> Void) {
        guard let currentUID = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }

        db.collection("users")
            .document(currentUID)
            .collection("friends")
            .whereField("status", isEqualTo: "accepted")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching friends: \(error.localizedDescription)")
                    completion([])
                    return
                }

                let friends = snapshot?.documents.compactMap { doc -> UserProfile? in
                    let data = doc.data()
                    return UserProfile(
                        id: doc.documentID,
                        displayName: data["displayName"] as? String ?? "(No Name)",
                        email: data["email"] as? String ?? "(No Email)"
                    )
                } ?? []

                completion(friends)
            }
    }

    // MARK: - Fetch Pending Friend Requests
    func fetchPendingRequests(completion: @escaping ([UserProfile]) -> Void) {
        guard let currentUID = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }

        db.collection("users")
            .document(currentUID)
            .collection("friends")
            .whereField("status", isEqualTo: "pending")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching pending requests: \(error.localizedDescription)")
                    completion([])
                    return
                }

                let pendingRequests = snapshot?.documents.compactMap { doc -> UserProfile? in
                    let data = doc.data()
                    return UserProfile(
                        id: doc.documentID,
                        displayName: data["displayName"] as? String ?? "(No Name)",
                        email: data["email"] as? String ?? "(No Email)"
                    )
                } ?? []

                completion(pendingRequests)
            }
    }

    // MARK: - Fetch Users Not Friends (For ExploreFriendsView)
    func fetchUsersNotFriends(completion: @escaping ([UserProfile]) -> Void) {
        guard let currentUID = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }

        // Step 1: Fetch friend IDs (both accepted and pending)
        db.collection("users").document(currentUID).collection("friends")
            .getDocuments { friendSnapshot, error in
                if let error = error {
                    print("Error fetching friends: \(error.localizedDescription)")
                    completion([])
                    return
                }

                var excludedUserIDs: Set<String> = [currentUID]
                friendSnapshot?.documents.forEach { doc in
                    excludedUserIDs.insert(doc.documentID)
                }

                // Step 2: Fetch all users and exclude friends
                self.db.collection("users").getDocuments { snapshot, error in
                    if let error = error {
                        print("Error fetching users: \(error.localizedDescription)")
                        completion([])
                        return
                    }

                    let users = snapshot?.documents.compactMap { doc -> UserProfile? in
                        let uid = doc.documentID
                        guard !excludedUserIDs.contains(uid) else { return nil }
                        let data = doc.data()
                        return UserProfile(
                            id: uid,
                            displayName: data["displayName"] as? String ?? "(No Name)",
                            email: data["email"] as? String ?? "(No Email)"
                        )
                    } ?? []

                    completion(users)
                }
            }
    }
}
