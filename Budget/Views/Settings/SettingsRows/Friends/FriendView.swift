//
//  FriendView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-11-08.
//

import SwiftUI

struct FriendView: View {
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var friendsViewModel: FriendsViewModel
    
    @State var profilePicture: UIImage? = nil
    
    private let friend: User
    
    private let rowHeight: CGFloat
    private let pictureSize: CGFloat
    
    private let nameSize: Font = .headline
    private let numberSize: Font = .subheadline
    
    init(friend: User, rowHeight: CGFloat) {
        self.friend = friend
        self.rowHeight = rowHeight
        self.pictureSize = rowHeight - 10
    }
    
    var body: some View {
        NavigationLink {
            FriendDetailView(friend: self.friend)
        } label: {
            HStack(spacing: 15) {
                ProfilePicture(uiImage: profilePicture, failImage: Image(systemName: "person.circle"))
                    .frame(width: self.pictureSize, height: self.pictureSize)
                    .clipShape(Circle())
                    .onLoad {
                        self.friendsViewModel.getPicture(uid: self.friend.id) { uiImage, error in
                            if let error = error {
                                self.errorHandling.handle(error: error)
                                return
                            }
                            
                            // Success
                            self.profilePicture = uiImage
                        }
                    }
                VStack(alignment: .leading) {
                    // TODO - Format numbers and make it pretty
                    Text(self.friend.name)
                        .font(self.nameSize)
                    Text(self.friend.phone)
                        .font(self.numberSize)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(minHeight: self.rowHeight)
    }
}
