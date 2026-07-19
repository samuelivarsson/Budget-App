//
//  FriendsView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-19.
//  v2 — grouped by friend group (like the "Alla vänner" sheet), with avatar rows.
//

import Firebase
import SwiftUI

struct FriendsView: View {
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var fsViewModel: FirestoreViewModel
    @EnvironmentObject private var userViewModel: UserViewModel

    @State private var expandedGroups: Set<String> = []
    private let collapseLimit = 4

    var body: some View {
        Form {
            let favourites = self.userViewModel.getFavouritesSorted()
            if !favourites.isEmpty {
                Section {
                    self.section(key: "__fav", members: favourites)
                } header: {
                    Text("favourites")
                }
            }

            ForEach(self.userViewModel.getFriendGroupsSorted(), id: \.self) { group in
                let members = self.userViewModel.getAllNonFavouriteFriendsSorted().filter {
                    self.userViewModel.getFriendGroup(friendId: $0.id) == group
                }
                if !members.isEmpty {
                    Section {
                        self.section(key: group.isEmpty ? "__nogroup" : group, members: members)
                    } header: {
                        Text(verbatim: self.groupHeader(group, count: members.count))
                    }
                }
            }
        }
        .iosFormBackground()
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

    @ViewBuilder
    private func section(key: String, members: [any Named]) -> some View {
        let expanded = self.expandedGroups.contains(key)
        let shown = expanded ? members : Array(members.prefix(self.collapseLimit))
        ForEach(shown, id: \.id) { member in
            if let user = member as? User {
                FriendView(friend: user)
            } else if let customFriend = member as? CustomFriend {
                CustomFriendView(friend: customFriend)
            }
        }
        .onDelete { offsets in
            self.deleteMembers(offsets: offsets, members: shown)
        }
        if !expanded && members.count > self.collapseLimit {
            Button {
                self.expandedGroups.insert(key)
            } label: {
                Text(String(format: "showMoreCount".localizeString(), members.count - self.collapseLimit))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private func groupHeader(_ group: String, count: Int) -> String {
        let name = group.isEmpty ? "noGroup".localizeString() : group
        let word = (count == 1 ? "friend" : "friends").localizeString().lowercased()
        return "\(name) · \(count) \(word)"
    }

    private func deleteMembers(offsets: IndexSet, members: [any Named]) {
        withAnimation {
            offsets.map { members[$0] }.forEach { member in
                if let user = member as? User {
                    self.userViewModel.deleteFriend(friend: user) { error in
                        if let error = error { self.errorHandling.handle(error: error) }
                    }
                } else if let customFriend = member as? CustomFriend {
                    self.userViewModel.deleteCustomFriend(customFriend: customFriend) { error in
                        if let error = error { self.errorHandling.handle(error: error) }
                    }
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
