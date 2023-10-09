//
//  FriendDetailView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-20.
//

import Firebase
import FirebaseFirestore
import SwiftUI

struct FriendDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var friendsViewModel: FriendsViewModel
    
    @State private var uiImage: UIImage?
    @State private var pictureLoading = false
    
    @Binding var friend: User
    
    private let pictureSize: CGFloat = 150
    
    var body: some View {
        Form {
            HStack {
                Spacer()
                VStack {
                    if self.pictureLoading {
                        ProgressView()
                            .frame(width: self.pictureSize, height: self.pictureSize)
                    } else {
                        ZStack {
                            ProfilePicture(uiImage: self.uiImage, failImage: Image(systemName: "person.circle"))
                                .frame(width: self.pictureSize, height: self.pictureSize)
                                .clipShape(Circle())
                            
                            if self.userViewModel.isFriendFavourite(user: self.friend) {
                                Image(systemName: "heart.fill")
                                    .offset(x: self.pictureSize/2, y: -self.pictureSize/2)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    Text(self.friend.name)
                        .font(.headline)
                }
                Spacer()
            }
            .listRowBackground(self.colorScheme == .dark ? Color.background : Color.secondaryBackground)

            Section {
                HStack {
                    Text("name")
                    Spacer()
                    Text(self.friend.name)
                }
                
                HStack {
                    Text("phone")
                    Spacer()
                    Text(self.friend.phone)
                }
                HStack {
                    Text("email")
                    Spacer()
                    Text(self.friend.email)
                }
                NavigationLink {
                    EditFriendGroupView(friend: self.friend)
                } label: {
                    HStack {
                        Text("group")
                        Spacer()
                        Text(self.userViewModel.getFriendGroup(friendId: self.friend.id))
                    }
                }
            }
            
            Section {
                Button {
                    self.toggleFavourite()
                } label: {
                    HStack {
                        Spacer()
                        let isFavourite = self.userViewModel.isFriendFavourite(user: self.friend)
                        Text(isFavourite ? "removeFromFavourites" : "makeFavourite")
                            .foregroundColor(isFavourite ? .red : .accentColor)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("editFriend")
        .navigationBarTitleDisplayMode(.inline)
        .onLoad {
            self.pictureLoading = true
            self.friendsViewModel.getPicture(uid: self.friend.id) { uiImage, error in
                self.pictureLoading = false
                
                if let error = error {
                    self.errorHandling.handle(error: error)
                    return
                }
                
                // Success
                self.uiImage = uiImage
            }
        }
    }
    
    private func toggleFavourite() {
        self.userViewModel.toggleFriendFavourite(friendId: self.friend.id) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
        }
    }
}
