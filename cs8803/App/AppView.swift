//
//  AppView.swift
//  cs8803
//
//  Created by Ethan Yan on 19/1/25.
//

import SwiftUI
import FirebaseAuth

struct AppView: View {
    @State private var currentUser: User? = Auth.auth().currentUser

    var body: some View {
        NavigationView {
            Group {
                if currentUser == nil {
                    LoginView()
                } else {
                    HomeView()
                }
            }
            .onAppear {
                // Listen for changes in auth state
                Auth.auth().addStateDidChangeListener { _, user in
                    currentUser = user
                }
            }
        }
    }
}
