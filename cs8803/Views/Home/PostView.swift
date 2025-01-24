//
//  PostView.swift
//  cs8803
//
//  Created by Ethan Yan on 19/1/25.
//

import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore

struct PostView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var caption: String = ""
    @State private var statusMessage: String?
    @State private var uploadProgress: Double? = nil // For progress bar
    private let imageUploadService = ImageUploadService()
    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack {
                // Display the selected image if available
                if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 300, maxHeight: 300)
                        .cornerRadius(8)
                        .padding(.bottom, 16)
                } else {
                    Text("No Image Selected")
                        .foregroundColor(.gray)
                        .padding(.bottom, 16)
                }

                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Text("Select Image")
                        .foregroundColor(.blue)
                }
                .onChange(of: selectedItem) { newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                            selectedImageData = data
                        }
                    }
                }

                TextField("Enter Caption", text: $caption)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Upload Post") {
                    uploadPost()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)

                if let statusMessage = statusMessage {
                    Text(statusMessage)
                        .foregroundColor(.blue)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("New Post")
        }
    }

    private func uploadPost() {
        guard let data = selectedImageData else {
            statusMessage = "Please select an image."
            return
        }

        guard let user = Auth.auth().currentUser else {
            statusMessage = "User not authenticated."
            return
        }

        let publicId = "posts-\(UUID().uuidString)"
        imageUploadService.uploadImage(data: data, publicId: publicId) { result in
            switch result {
            case .success(let secureUrl):
                savePostToFirestore(imageURL: secureUrl)
            case .failure(let error):
                statusMessage = "Upload failed: \(error.localizedDescription)"
            }
        }
    }

    private func savePostToFirestore(imageURL: String) {
        guard let user = Auth.auth().currentUser else { return }

        let postData: [String: Any] = [
            "userId": user.uid,
            "caption": caption,
            "imageURL": imageURL,
            "timestamp": Timestamp()
        ]

        db.collection("posts").addDocument(data: postData) { error in
            if let error = error {
                statusMessage = "Error saving post: \(error.localizedDescription)"
            } else {
                statusMessage = "Post uploaded successfully!"
            }
        }
    }
}
