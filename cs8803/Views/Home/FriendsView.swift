//
//  FriendsView.swift
//  cs8803
//
//  Created by Ethan Yan on 21/1/25.
//

import SwiftUI

struct FriendsView: View {
    @AppStorage("selectedFriendTab") private var selectedTab = 0 // Store selected tab

    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                ExploreFriendsView()
                    .tabItem {
                        Label("Explore", systemImage: "magnifyingglass")
                    }
                    .tag(0)

                MyFriendsView()
                    .tabItem {
                        Label("My Friends", systemImage: "person.2.fill")
                    }
                    .tag(1)
            }
            .navigationTitle("Friends")
        }
    }
}
