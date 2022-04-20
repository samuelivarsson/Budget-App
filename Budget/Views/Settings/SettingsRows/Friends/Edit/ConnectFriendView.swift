//
//  ConnectFriendView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-19.
//

import SwiftUI

struct ConnectFriendView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Friend.name, ascending: true)],
        animation: .default)
    private var friends: FetchedResults<Friend>
    
    @State private var email: String = ""
    
    private var friend: Friend
    
    init(friend: Friend) {
        self.friend = friend
        self._email = State(initialValue: friend.email ?? "")
    }
    
    var body: some View {
        Form {
            Section {
                TextField("email", text: $email, prompt: Text("userEmail"))
            } header: {
                Text("email")
            }
            
            Section {
                HStack {
                    Spacer()
                    Button("apply") {
                        addUserAsFriendAndConnect()
                        presentationMode.wrappedValue.dismiss()
                    }
                    Spacer()
                }
            } footer: {
                Text("connectFriendConsequence")
            }
        }
        .navigationTitle("connectFriend")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func addUserAsFriendAndConnect() {
        
    }
}

struct ConnectFriendView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectFriendView(friend: Friend())
    }
}
