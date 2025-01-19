//
//  HomeView.swift
//  cs8803
//
//  Created by Ethan Yan on 19/1/25.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        // 1) Use a TabView for the main navigation once user is logged in
        TabView {
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "house")
                }

            PostView()
                .tabItem {
                    Label("Post", systemImage: "plus.circle")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
    }
}
