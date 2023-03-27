//
//  EditFriendPhoneView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-20.
//

import SwiftUI

struct EditFriendPhoneView: View {
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel
    
    @State private var friend: CustomFriend = CustomFriend(name: "", phone: "")
    @State private var phone: String = ""
    @State private var applyLoading = false
    
    init(customFriend: CustomFriend) {
        self.friend = customFriend
        self._phone = State(initialValue: customFriend.name)
    }
    
    var body: some View {
        Form {
            Section("phone") {
                TextField("phone", text: $phone, prompt: Text("friendsPhone"))
            }
            
            HStack {
                Spacer()
                Button {
                    self.editFriend()
                } label: {
                    if self.applyLoading {
                        ProgressView()
                    } else {
                        Text("apply")
                    }
                }
                Spacer()
            }
        }
        .navigationTitle("editFriendPhone")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func editFriend() {
        self.applyLoading = true
        self.friend.phone = phone
        
        self.userViewModel.editCustomFriend(friend: self.friend) { error in
            self.applyLoading = false
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
            self.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct EditFriendPhoneView_Previews: PreviewProvider {
    static var previews: some View {
        EditFriendPhoneView(customFriend: CustomFriend(name: "", phone: ""))
            .environmentObject(ErrorHandling())
    }
}
