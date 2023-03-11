//
//  CustomFriendView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-11-08.
//

import SwiftUI

struct CustomFriendView: View {
    private let friend: CustomFriend
    
    private let rowHeight: CGFloat
    
    private let nameSize: Font = .headline
    private let numberSize: Font = .subheadline
    
    init(friend: CustomFriend, rowHeight: CGFloat) {
        self.friend = friend
        self.rowHeight = rowHeight
    }
    
    var body: some View {
        NavigationLink {
            CustomFriendDetailView(friend: friend)
        } label: {
            VStack(alignment: .leading) {
                Text(self.friend.name)
                    .font(self.nameSize)
                Text(self.friend.phone)
                    .font(self.numberSize)
                    .foregroundColor(.secondary)
            }
        }
        .frame(minHeight: self.rowHeight)
    }
}

