//
//  AddFriendView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-20.
//

import SwiftUI
import Firebase

struct AddFriendView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var fsViewModel: FirestoreViewModel
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)],
                  animation: .default)
    private var friends: FetchedResults<Friend>
    
    @State private var email: String = ""
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var addUserLoading: Bool = false
    
    var body: some View {
        Form {
            Section("addUserByEmail") {
                emailView
                HStack {
                    Spacer()
                    if addUserLoading {
                        ProgressView()
                    } else {
                        Button("add") {
                            addUserAsFriend(email: email)
                        }
                    }
                    Spacer()
                }
            }
            
            Section("addFriendManually") {
                nameView
                phoneView
                Button("add") {
                    addFriend(name: self.name, phone: self.phone)
                    presentationMode.wrappedValue.dismiss()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                
            }
        }
        .navigationTitle("addFriend")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var emailView: some View {
        HStack(spacing: 30) {
            Text("email")
            TextField("email", text: $email, prompt: Text("userEmail"))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .keyboardType(.emailAddress)
                .multilineTextAlignment(.trailing)
        }
    }
    
    private var nameView: some View {
        HStack(spacing: 30) {
            Text("name")
            TextField("name", text: $name, prompt: Text("friendsName"))
                .textInputAutocapitalization(.words)
                .multilineTextAlignment(.trailing)
        }
    }
    
    private var phoneView: some View {
        HStack(spacing: 30) {
            Text("phone")
            TextField("phone", text: $phone, prompt: Text("friendsPhone"))
                .textInputAutocapitalization(.never)
                .keyboardType(.phonePad)
                .disableAutocorrection(true)
                .multilineTextAlignment(.trailing)
        }
    }
    
    private func addFriend(name: String, phone: String) {
        withAnimation {
            let newFriend = Friend(context: viewContext)
            newFriend.id = UUID()
            newFriend.name = name
            newFriend.phone = phone
            newFriend.custom = true
            newFriend.creator = self.authViewModel.auth.currentUser?.uid ?? ""
            
            do {
                try viewContext.save()
            } catch {
                self.errorHandling.handle(error: error)
            }
        }
    }
    
    private func addFriend(user: [String: Any]) {
        withAnimation {
            let newFriend = Friend(context: viewContext)
            newFriend.id = UUID()
            newFriend.name = user["name"] as? String ?? ""
            newFriend.phone = user["phone"] as? String ?? ""
            newFriend.email = user["email"] as? String
            newFriend.uid = user["uid"] as? String
            newFriend.custom = false
            newFriend.creator = self.authViewModel.auth.currentUser?.uid ?? ""
            
            do {
                try viewContext.save()
            } catch {
                self.errorHandling.handle(error: error)
            }
        }
    }
    
    // QTODO - Send friend request?
    private func addUserAsFriend(email: String) {
        // You can't add yourself as friend
        guard email.lowercased() != authViewModel.auth.currentUser?.email?.lowercased() else {
            self.errorHandling.handle(error: InputError.addYourself)
            return
        }
        // A user can only be one of your friends
        guard !friends.contains(where: { $0.email?.lowercased() ?? "" == email.lowercased() }) else {
            self.errorHandling.handle(error: InputError.userIsAlreadyFriend)
            return
        }
        
        self.addUserLoading = true
        
        self.fsViewModel.getUserFromEmail(email: email) { user, error in
            self.addUserLoading = false
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            guard let user = user else {
                let info = "Found nil when extracting user in addUserAsFriend in AddFriendView"
                print(info)
                self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
                return
            }
            
            // Success
            self.addFriend(user: user)
            
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct AddFriendView_Previews: PreviewProvider {
    static var previews: some View {
        AddFriendView()
            .environmentObject(ErrorHandling())
    }
}
