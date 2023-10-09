//
//  SeeAllFriendsView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-10-07.
//

import SwiftUI

struct SeeAllFriendsView: View {
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel

    @Binding var participants: [Participant]
    @State private var selectedRows: Set<String> = .init()

    var body: some View {
        Form {
            Section("favourites") {
                ForEach(self.userViewModel.getFavouritesSorted(), id: \.id) { favouriteFriend in
                    MultiSelectRow(friend: favouriteFriend, selectedItems: self.$selectedRows)
                }
            }

            ForEach(self.userViewModel.getFriendGroupsSorted(), id: \.self) { group in
                let friendsInGroup: [any Named] = self.userViewModel.getFriendsSorted().filter { self.userViewModel.getFriendGroup(friendId: $0.id) == group } + self.userViewModel.getCustomFriendsSorted().filter { $0.group == group }

                let groupName = group.isEmpty ? "noGroup" : group
                Section(LocalizedStringKey(groupName)) {
                    ForEach(friendsInGroup, id: \.id) { friend in
                        MultiSelectRow(friend: friend, selectedItems: self.$selectedRows)
                    }
                }
            }
        }
        .navigationTitle("chooseFriends")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    self.selectedRows.forEach { friendId in
                        if friendId != self.userViewModel.user.id {
                            if let friendName = self.userViewModel.getName(friendId: friendId) {
                                if !self.participants.contains(where: { $0.userId == friendId }) {
                                    self.participants.append(Participant(userId: friendId, userName: friendName))
                                }
                            } else {
                                self.errorHandling.handle(error: ApplicationError.unexpectedNil("Found nil when extracting friendName for friend with id \(friendId) in toolbar in SeeAllFriendsView"))
                            }
                        }
                    }
                    self.presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("choose")
                }
            }
        }
        .onLoad {
            self.participants.forEach { participant in
                self.selectedRows.insert(participant.userId)
            }
        }
    }
}

struct MultiSelectRow: View {
    var friend: any Named

    @Binding var selectedItems: Set<String>

    var isSelected: Bool {
        selectedItems.contains(friend.id)
    }

    var body: some View {
        Button {
            if self.isSelected {
                self.selectedItems.remove(self.friend.id)
            } else {
                self.selectedItems.insert(self.friend.id)
            }
        } label: {
            HStack {
                Text(self.friend.name)
                    .foregroundStyle(Color.primary)
                Spacer()
                if self.isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
}

// #Preview {
//    SeeAllFriendsView()
// }
