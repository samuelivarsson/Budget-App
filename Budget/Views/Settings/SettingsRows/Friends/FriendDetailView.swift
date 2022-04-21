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
    
    private var friend: Friend
    
    init(friend: Friend) {
        self.friend = friend
    }
    
    var body: some View {
        Form {
            Section {
                VStack {
                    // TODO - Add picture and name, requires that image is saved on database
                }
            }
            
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
    }
}
