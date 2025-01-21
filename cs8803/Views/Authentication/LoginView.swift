//
//  LoginView.swift
//  cs8803
//
//  Created by Ethan Yan on 18/1/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSignUp: Bool = false  // Toggle for sign-up vs. login
    @State private var authError: String?

    private let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.65, green: 0.85, blue: 1.0),  // A pale sky-blue
            Color(red: 0.78, green: 0.92, blue: 1.0)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack {
            // 1) Full-screen background gradient
            backgroundGradient
                .ignoresSafeArea()

            // 2) Main container
            VStack(spacing: 16) {
                Text(isSignUp ? "Create Account" : "Welcome Back")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 8)

                // Card-like background for the textfields & buttons
                VStack(spacing: 20) {
                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)

                    // Show error message if there is one
                    if let error = authError {
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Button(action: {
                        if isSignUp {
                            signUpUser()
                        } else {
                            signInUser()
                        }
                    }) {
                        Text(isSignUp ? "Sign Up" : "Login")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }

                    // Toggle between login and signup
                    Button(action: {
                        isSignUp.toggle()
                    }) {
                        Text(isSignUp
                             ? "Already have an account? Login"
                             : "Don’t have an account? Sign Up")
                            .foregroundColor(.blue)
                            .underline()
                    }
                }
                .padding()
                .background(.ultraThinMaterial)   // or Color.white for a solid card
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                .padding(.horizontal, 24)
            }
            .padding()
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(true)
    }

    // MARK: - Firebase Methods

    private func signInUser() {
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            if let error = error {
                authError = error.localizedDescription
            } else {
                authError = nil
                // Successfully signed in;
                // AppView will update automatically because of addStateDidChangeListener
            }
        }
    }

    private func signUpUser() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                authError = error.localizedDescription
            } else {
                // Successfully signed up
                authError = nil
                
                if let user = result?.user {
                    // Save email to Firestore
                    let docRef = Firestore.firestore().collection("users").document(user.uid)
                    docRef.setData(["email": self.email], merge: true) { err in
                        if let err = err {
                            print("Error saving email to Firestore: \(err.localizedDescription)")
                        } else {
                            print("Email saved to Firestore for user \(user.uid).")
                        }
                    }
                }
            }
        }
    }
}
