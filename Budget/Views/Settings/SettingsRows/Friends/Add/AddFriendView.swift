//
//  AddFriendView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-20.
//

import SwiftUI
import Firebase

struct AddFriendView: View {
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var fsViewModel: FirestoreViewModel
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var usersLookupViewModel: UsersLookupViewModel
    
    @State private var search: String = ""
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var addUserLoading: Bool = false
    @State var keyword: String = ""
    
    var body: some View {
        Form {
            Section("searchForUser") {
                ProfileSearchView()
            }
            
            Section("addFriendManually") {
                nameView
                phoneView
                Button("add") {
                    addCustomFriend(name: self.name, phone: self.phone)
                    presentationMode.wrappedValue.dismiss()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                
            }
        }
        .navigationTitle("addFriend")
        .navigationBarTitleDisplayMode(.inline)
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
    
    private func addCustomFriend(name: String, phone: String) {
        withAnimation {
            let newFriend = CustomFriend(name: name, phone: phone)
            
            self.userViewModel.addCustomFriend(friend: newFriend) { error in
                if let error = error {
                    self.errorHandling.handle(error: error)
                    return
                }
                
                // Success
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
