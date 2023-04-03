//
//  FriendsView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-19.
//

import Firebase
import SwiftUI

struct FriendsView: View {
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var fsViewModel: FirestoreViewModel
    @EnvironmentObject private var userViewModel: UserViewModel
    
    private let rowHeight: CGFloat = 80
    
    var body: some View {
        Form {
            let favouriteFriends = self.userViewModel.getFriendsSorted(favourites: true)
            if favouriteFriends.count > 0 {
                Section {
                    self.getFriends(friends: favouriteFriends)
                } header: {
                    Text("favourites")
                }
            }
            
            let otherFriends = self.userViewModel.getFriendsSorted(favourites: false)
            if otherFriends.count > 0 {
                Section {
                    self.getFriends(friends: otherFriends)
                } header: {
                    Text("otherFriends")
                }
            }
            
            let customFriends = self.userViewModel.getCustomFriendsSorted()
            if customFriends.count > 0 {
                Section {
                    ForEach(self.userViewModel.getCustomFriendsSorted()) { friend in
                        CustomFriendView(friend: friend, rowHeight: self.rowHeight)
                    }
                    .onDelete(perform: self.deleteCustomFriends)
                } header: {
                    Text("customFriends")
                }
            }
        }
        .navigationTitle("friends")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem {
                NavigationLink {
                    AddFriendView()
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
    }
    
    private func getFriends(friends: [User]) -> some View {
        ForEach(friends) { friend in
            FriendView(friend: friend, rowHeight: self.rowHeight)
        }
        .onDelete { offsets in
            self.deleteFriends(offsets: offsets, friends: friends)
        }
    }
    
    private func deleteFriends(offsets: IndexSet, friends: [User]) {
        withAnimation {
            offsets.map { friends[$0] }.forEach { friend in
                self.userViewModel.deleteFriend(friend: friend) { error in
                    if let error = error {
                        self.errorHandling.handle(error: error)
                        return
                    }
                    
                    // Success
                }
            }
        }
    }
    
    private func deleteCustomFriends(offsets: IndexSet) {
        withAnimation {
            offsets.map { self.userViewModel.getCustomFriendsSorted()[$0] }.forEach { customFriend in
                self.userViewModel.deleteCustomFriend(customFriend: customFriend) { error in
                    if let error = error {
                        self.errorHandling.handle(error: error)
                        return
                    }
                    
                    // Success
                }
            }
        }
    }
}

struct FriendsView_Previews: PreviewProvider {
    static var previews: some View {
        FriendsView()
            .environmentObject(ErrorHandling())
    }
}
