//
//  FriendDetailView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-20.
//

import SwiftUI

struct FriendDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var friendsViewModel: FriendsViewModel
    
    @State private var uiImage: UIImage?
    @State private var pictureLoading = false
    
    private var friend: Friend
    
    init(friend: Friend) {
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
                    
                    Text(friend.name ?? "")
                        .font(.headline)
                }
                Spacer()
            }
            .listRowBackground(colorScheme == .dark ? Color.background : Color.secondaryBackground)

            Section {
                NavigationLink {
                    EditFriendNameView(friend: friend)
                } label: {
                    HStack {
                        Text("name")
                        Spacer()
                        Text(friend.name ?? "")
                    }
                }
                NavigationLink {
                    EditFriendPhoneView(friend: friend)
                } label: {
                    HStack {
                        Text("phone")
                        Spacer()
                        Text(friend.phone ?? "")
                    }
                }
                NavigationLink {
                    ConnectFriendView(friend: friend)
                } label: {
                    HStack {
                        Text("email")
                        Spacer()
                        Text(friend.email ?? "")
                    }
                }
            } footer: {
                Text("onlyNonCustom")
            }
        }
        .navigationTitle("editFriend")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard let uid = self.friend.uid else {
                let info = "Found nil when extracting uid in onAppear in FriendDetailView"
                print(info)
                self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
                return
            }
            if let image = self.friendsViewModel.friendPictures[uid] {
                self.uiImage = image
                return
            }
            self.pictureLoading = true
            Utility.getProfilePictureFromUID(uid: uid) { image, error in
                if let error = error {
                    self.errorHandling.handle(error: error)
                    return
                }
                guard let image = image else {
                    let info = "Found nil when extracting image in onAppear in FriendDetailView"
                    print(info)
                    self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
                    return
                }
                self.uiImage = image
                self.friendsViewModel.friendPictures[uid] = image
                self.pictureLoading = false
            }
        }
    }
}

struct FriendDetailView_Previews: PreviewProvider {
    static var previews: some View {
        FriendDetailView(friend: Friend())
            .environmentObject(ErrorHandling())
            .environmentObject(AuthViewModel())
            .environmentObject(FriendsViewModel())
    }
}
