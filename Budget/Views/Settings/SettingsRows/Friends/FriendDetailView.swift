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
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var isShowPhotoLibrary = false
    
    private var friend: Friend
    
    init(friend: Friend) {
        self.friend = friend
    }
    
    var body: some View {
        Form {
            HStack {
                Spacer()
                VStack {
                    // TODO - Add picture and name, requires that image is saved on database
                    UserPicture(user: authViewModel.auth.currentUser)
                        .clipShape(Circle())
                        .frame(height: 150)
                    
                    Text(friend.name ?? "")
                        .font(.headline)
                }
                Spacer()
            }.listRowBackground(Color.background)
            // TODO - change to extension background everywhere

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
    }
}

struct FriendDetailView_Previews: PreviewProvider {
    static var previews: some View {
        FriendDetailView(friend: Friend())
            .environmentObject(ErrorHandling())
            .environmentObject(AuthViewModel())
    }
}
