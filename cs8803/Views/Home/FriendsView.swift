//
//  FriendsView.swift
//  cs8803
//
//  Created by Ethan Yan on 21/1/25.
//

import SwiftUI

struct FriendsView: View {
    @State private var selectedTab: FriendsTab = .explore

    var body: some View {
        NavigationView {
            VStack {
                // 1) Segment Picker up top
                Picker("Choose View", selection: $selectedTab) {
                    Text("Explore").tag(FriendsTab.explore)
                    Text("My Friends").tag(FriendsTab.myFriends)
                }
                .pickerStyle(.segmented)
                .padding()

                // 2) Show the corresponding subview based on selectedTab
                switch selectedTab {
                case .explore:
                    ExploreFriendsView()
                case .myFriends:
                    MyFriendsView()
                }
                
                Spacer()
            }
            .navigationTitle("Friends")
        }
    }
}

// An enum to track which segment is selected
enum FriendsTab {
    case explore
    case myFriends
}
