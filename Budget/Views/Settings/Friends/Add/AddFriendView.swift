//
//  AddFriendView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-20.
//

import Firebase
import SwiftUI

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
    @State private var group: String = ""
    @State private var newGroup: String = ""
    @State private var isNewGroup: Bool = false
    @State private var addUserLoading: Bool = false
    @State var keyword: String = ""

    @FocusState var isInputActive: Bool

    var body: some View {
        Form {
            Section("searchForUser") {
                ProfileSearchView(isInputActive: self.$isInputActive)
            }

            Section("addFriendManually") {
                nameView
                phoneView
                groupPicker
                Button("add") {
                    let finalGroup = self.isNewGroup ? self.newGroup.capitalized : self.group
                    addCustomFriend(name: self.name, phone: self.phone, group: finalGroup)
                    presentationMode.wrappedValue.dismiss()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .iosFormBackground()
        .navigationTitle("addFriend")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var nameView: some View {
        HStack(spacing: 30) {
            Text("name")
            TextField("name", text: $name, prompt: Text("friendsName"))
                .textInputAutocapitalization(.words)
                .multilineTextAlignment(.trailing)
                .focused(self.$isInputActive)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()

                        Button("Done") {
                            self.isInputActive = false
                        }
                    }
                }
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
                .focused(self.$isInputActive)
        }
    }
    
    private var groupPicker: some View {
        Group {
            Picker("group", selection: self.$group) {
                ForEach(self.userViewModel.getFriendGroupsSorted(), id: \.self) { group in
                    Text(LocalizedStringKey(group.isEmpty ? "noGroup" : group)).tag(group)
                }
            }
            .pickerStyle(.menu)
            .disabled(self.isNewGroup)

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
    }

    private func addCustomFriend(name: String, phone: String, group: String) {
        withAnimation {
            let newFriend = CustomFriend(name: name, phone: phone, group: group)

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
