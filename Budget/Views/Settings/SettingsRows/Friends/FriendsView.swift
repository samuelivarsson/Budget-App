//
//  FriendsView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-19.
//

import SwiftUI
import Firebase

struct FriendsView: View {
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var fsViewModel: FirestoreViewModel
    @EnvironmentObject private var userViewModel: UserViewModel
    
    private let rowHeight: CGFloat = 80
    
    var body: some View {
        Form {
            Section {
                ForEach(self.userViewModel.friends) { friend in
                    FriendView(friend: friend, rowHeight: self.rowHeight)
                }
                .onDelete(perform: deleteFriends)
            } header: {
                Text("friends")
            }
            
            if (self.userViewModel.user.customFriends).count > 0 {
                Section {
                    ForEach(self.userViewModel.user.customFriends) { friend in
                        CustomFriendView(friend: friend, rowHeight: self.rowHeight)
                    }
                    .onDelete(perform: deleteCustomFriends)
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
    
    private func deleteFriends(offsets: IndexSet) {
        withAnimation {
            offsets.map { self.userViewModel.friends[$0] }.forEach { friend in
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
        let user = self.userViewModel.user
        withAnimation {
            offsets.map { user.customFriends[$0] }.forEach { customFriend in
                self.userViewModel.deleteCustomFriend(customFriend: customFriend) { error in
                    if let error = error {
                        self.errorHandling.handle(error: error)
                        return
                    }
                    
                    // Success
                    print("hej")
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
