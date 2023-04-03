//
//  EditFriendNameView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-20.
//

import SwiftUI

struct EditFriendNameView: View {
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel
    
    @State private var friend: CustomFriend
    @State private var applyLoading = false
    
    init(customFriend: CustomFriend) {
        self._friend = State(initialValue: customFriend)
    }
    
    var body: some View {
        Form {
            Section("name") {
                TextField("name", text: self.$friend.name, prompt: Text("friendsName"))
            }
            
            HStack {
                Spacer()
                Button {
                    if !self.applyLoading {
                        self.editFriend()
                    }
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
        .navigationTitle("editFriendName")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func editFriend() {
        self.applyLoading = true
        
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

struct EditFriendNameView_Previews: PreviewProvider {
    static var previews: some View {
        EditFriendNameView(customFriend: CustomFriend(name: "", phone: ""))
            .environmentObject(ErrorHandling())
    }
}
