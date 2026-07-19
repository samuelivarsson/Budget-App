//
//  CustomFriendView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-11-08.
//

import SwiftUI

struct CustomFriendView: View {
    private let friend: CustomFriend

    init(friend: CustomFriend) {
        self.friend = friend
    }

    var body: some View {
        NavigationLink {
            CustomFriendDetailView(friend: self.friend)
        } label: {
            HStack(spacing: 12) {
                // Dashed ring marks an account-less contact (same cue as Ställningar).
                ZStack {
                    IOSPersonAvatar(name: self.friend.name, id: self.friend.id, size: 40)
                    Circle()
                        .strokeBorder(Color.primary.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                        .frame(width: 46, height: 46)
                }
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
