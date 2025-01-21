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

            // 2) Create or update doc in A’s subcollection => pending
            transaction.setData([
                "status": "pending",
                "requestSender": userA,
                "lastUpdated": FieldValue.serverTimestamp()
            ], forDocument: docRefInA, merge: true)

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
    
    // MARK: - Fetch My Friends
    func fetchAcceptedFriends(completion: @escaping ([String]) -> Void) {
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
                let friendIDs = snapshot?.documents.map { $0.documentID } ?? []
                completion(friendIDs)
            }
    }
}
