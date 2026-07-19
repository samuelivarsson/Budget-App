//
//  FriendView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-11-08.
//

import SwiftUI

struct FriendView: View {
    @State private var friend: User

    init(friend: User) {
        self._friend = State(initialValue: friend)
    }

    var body: some View {
        NavigationLink {
            FriendDetailView(friend: self.$friend)
        } label: {
            HStack(spacing: 12) {
                IOSPersonAvatar(name: self.friend.name, id: self.friend.id, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(self.friend.name)
                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                    if !self.friend.phone.isEmpty {
                        Text(self.friend.phone)
                            .font(.system(size: 13)).foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}
