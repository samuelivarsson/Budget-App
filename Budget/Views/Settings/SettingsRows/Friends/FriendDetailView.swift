//
//  FriendDetailView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-20.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct FriendDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var friendsViewModel: FriendsViewModel
    
    @State private var uiImage: UIImage?
    @State private var pictureLoading = false
    
    private var friend: User
    
    init(friend: User) {
        self.friend = friend
    }
    
    var body: some View {
        Form {
            HStack {
                Spacer()
                VStack {
                    // TODO - Check box if user is connected
                    if self.pictureLoading {
                        ProgressView()
                            .frame(width: 150, height: 150)
                    } else {
                        ProfilePicture(uiImage: uiImage, failImage: Image(systemName: "person.circle"))
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                    }
                    
                    Text(friend.name)
                        .font(.headline)
                }
                Spacer()
            }
            .listRowBackground(colorScheme == .dark ? Color.background : Color.secondaryBackground)

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
}
