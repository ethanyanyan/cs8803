//
//  ProfileView.swift
//  cs8803
//
//  Created by Ethan Yan on 19/1/25.
//


//
//  ProfileView.swift
//  cs8803
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("User Profile")
                    .font(.largeTitle)
                    .padding(.top, 40)

                // Add your profile info here, e.g. user avatar, name, etc.

                Button("Sign Out") {
                    do {
                        try Auth.auth().signOut()
                    } catch {
                        print("Sign out error: \(error.localizedDescription)")
                    }
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)

                Spacer()
            }
            .navigationTitle("Profile")
        }
    }
}
