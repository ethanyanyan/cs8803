//
//  HomeView.swift
//  cs8803
//
//  Created by Ethan Yan on 19/1/25.
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("You are logged in!")
                .font(.largeTitle)
                .padding()
            
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
        }
        .navigationTitle("Home")
    }
}
