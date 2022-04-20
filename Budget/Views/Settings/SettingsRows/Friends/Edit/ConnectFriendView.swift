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
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var fsViewModel: FirestoreViewModel
    
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
                        connectFriendToUser(userEmail: email)
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
    
    private func connectFriendToUser(userEmail: String) {
        guard email != authViewModel.auth.currentUser?.email else {
            errorHandling.handle(error: InputError.addYourself)
            return
        }
        
        fsViewModel.getUserFromEmail(email: userEmail) { user in
            guard let user = user else {
                errorHandling.handle(error: UserError.noUserWithEmail)
                return
            }
            
            friend.name = user["name"] as? String ?? ""
            friend.phone = user["phone"] as? String ?? ""
            friend.email = user["email"] as? String ?? ""
            friend.uid = user["uid"] as? String ?? ""
            friend.custom = false
            
            do {
                try viewContext.save()
            } catch {
                errorHandling.handle(error: error)
            }
        }
    }
}

struct ConnectFriendView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectFriendView(friend: Friend())
    }
}
