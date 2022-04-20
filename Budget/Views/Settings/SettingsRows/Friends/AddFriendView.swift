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
    @EnvironmentObject private var fsViewModel: FirestoreViewModel
    
    @State private var email: String = ""
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var addUserLoading: Bool = false
    
    let db = Firestore.firestore()
    
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
                            addUserLoading = true
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
    
    private func addFriend(name: String, phone: String, email: String? = nil, uid: String? = nil) {
        withAnimation {
            let newFriend = Friend(context: viewContext)
            newFriend.id = UUID()
            newFriend.name = name
            newFriend.phone = phone
            newFriend.email = email
            newFriend.uid = uid
            
            do {
                try viewContext.save()
            } catch {
                errorHandling.handle(error: error)
            }
        }
    }
    
    private func addUserAsFriend(email: String) {
        fsViewModel.getUserFromEmail(email: email) { user in
            addUserLoading = false
            if let user = user {
                addFriend(
                    name: user["name"] as? String ?? "",
                    phone: user["phone"] as? String ?? "",
                    email: user["email"] as? String,
                    uid: user["uid"] as? String
                )
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct AddFriendView_Previews: PreviewProvider {
    static var previews: some View {
        AddFriendView()
            .environmentObject(ErrorHandling())
    }
}
