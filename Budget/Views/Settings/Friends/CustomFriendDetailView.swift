//
//  CustomFriendDetailView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-10-06.
//

import SwiftUI

struct CustomFriendDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel
    
    private var friend: CustomFriend
    
    private let pictureSize: CGFloat = 150
    
    init(friend: CustomFriend) {
        self.friend = friend
    }
    
    var body: some View {
        Form {
            HStack {
                Spacer()
                VStack {
                    ZStack {
                        Image(systemName: "person.circle")
                            .resizable()
                            .frame(width: self.pictureSize, height: self.pictureSize)
                            .clipShape(Circle())
                        
                        if self.friend.favourite {
                            Image(systemName: "heart.fill")
                                .offset(x: self.pictureSize/2, y: -self.pictureSize/2)
                                .foregroundColor(.red)
                        }
                    }
                    
                    Text(self.friend.name)
                        .font(.headline)
                }
                Spacer()
            }
            .listRowBackground(self.colorScheme == .dark ? Color.background : Color.secondaryBackground)

            Section {
                NavigationLink {
                    EditFriendNameView(customFriend: self.friend)
                } label: {
                    HStack {
                        Text("name")
                        Spacer()
                        Text(self.friend.name)
                    }
                }
                NavigationLink {
                    EditFriendPhoneView(customFriend: self.friend)
                } label: {
                    HStack {
                        Text("phone")
                        Spacer()
                        Text(self.friend.phone)
                    }
                }
                NavigationLink {
                    EditFriendGroupView(friend: self.friend, isCustomFriend: true)
                } label: {
                    HStack {
                        Text("group")
                        Spacer()
                        Text(self.friend.group)
                    }
                }
            } footer: {
                Text("onlyNonCustom")
            }
            
            Section {
                Button {
                    self.toggleFavourite()
                } label: {
                    HStack {
                        Spacer()
                        let isFavourite = self.friend.favourite
                        Text(isFavourite ? "removeFromFavourites" : "makeFavourite")
                            .foregroundColor(isFavourite ? .red : .accentColor)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("editFriend")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func toggleFavourite() {
        self.userViewModel.toggleCustomFriendFavourite(friendId: self.friend.id) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
        }
    }
}

struct CustomFriendDetailView_Previews: PreviewProvider {
    static var previews: some View {
        CustomFriendDetailView(friend: CustomFriend(name: "", phone: ""))
    }
}
