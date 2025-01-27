//
//  FriendsView.swift
//  cs8803
//
//  Created by Ethan Yan on 21/1/25.
//

import SwiftUI

struct FriendsView: View {
    var body: some View {
        NavigationView {
            TabView {
                ExploreFriendsView()
                    .tabItem {
                        Label("Explore", systemImage: "magnifyingglass")
                    }

                MyFriendsView()
                    .tabItem {
                        Label("My Friends", systemImage: "person.2.fill")
                    }
            }
            .navigationTitle("Friends")
        }
    }
}
