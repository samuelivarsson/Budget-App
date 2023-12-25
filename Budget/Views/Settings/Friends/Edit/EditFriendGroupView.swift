//
//  EditFriendGroupView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-10-07.
//

import SwiftUI

struct EditFriendGroupView: View {
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel
    
    private let friendId: String
    private let isCustomFriend: Bool
    @State private var group: String = ""
    @State private var newGroup: String = ""
    @State private var isNewGroup: Bool = false
    @State private var applyLoading = false
    
    init(friend: any Named, isCustomFriend: Bool = false) {
        self.friendId = friend.id
        self.isCustomFriend = isCustomFriend
    }
    
    var body: some View {
        Form {
            Section("group") {
                HStack(spacing: 30) {
                    Picker("category", selection: self.$group) {
                        ForEach(self.userViewModel.getFriendGroupsSorted(), id: \.self) { group in
                            let groupName = group.isEmpty ? "noGroup" : group
                            Text(LocalizedStringKey(groupName)).tag(group)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(self.isNewGroup)
                    .onLoad {
                        self.group = self.userViewModel.getFriendGroup(friendId: self.friendId)
                    }
                }
                
                Toggle("newGroup", isOn: self.$isNewGroup)
                
                if self.isNewGroup {
                    HStack {
                        Text("groupName")
                        Spacer()
                        TextField("groupName", text: self.$newGroup)
                            .multilineTextAlignment(.trailing)
                    }
                }
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
        .navigationTitle("editFriendGroup")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func editFriend() {
        self.applyLoading = true
        let finalGroup = self.isNewGroup ? self.newGroup.capitalized : self.group
        
        if self.isCustomFriend {
            self.userViewModel.setCustomFriendGroup(group: finalGroup, friendId: self.friendId) { error in
                self.applyLoading = false
                if let error = error {
                    self.errorHandling.handle(error: error)
                    return
                }
                
                // Success
                self.presentationMode.wrappedValue.dismiss()
            }
            
            return
        }
        
        self.userViewModel.setFriendGroup(group: finalGroup, friendId: self.friendId) { error in
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

// #Preview {
//    EditFriendGroupView()
// }
