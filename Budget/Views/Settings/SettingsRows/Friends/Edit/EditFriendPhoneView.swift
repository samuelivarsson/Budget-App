//
//  EditFriendPhoneView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-20.
//

import SwiftUI

struct EditFriendPhoneView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    @EnvironmentObject private var errorHandling: ErrorHandling
    
    @State private var phone: String = ""
    
    private var friend: Friend
    
    init(friend: Friend) {
        self.friend = friend
        self._phone = State(initialValue: friend.phone ?? "")
    }
    
    var body: some View {
        Form {
            Section("phone") {
                TextField("phone", text: $phone, prompt: Text("friendsPhone"))
            }
            
            HStack {
                Spacer()
                Button("apply") {
                    editFriend()
                    presentationMode.wrappedValue.dismiss()
                }
                Spacer()
            }
        }
        .navigationTitle("editFriendPhone")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func editFriend() {
        friend.phone = phone
        
        do {
            try viewContext.save()
        } catch {
            errorHandling.handle(error: error)
        }
    }
}

struct EditFriendPhoneView_Previews: PreviewProvider {
    static var previews: some View {
        EditFriendPhoneView(friend: Friend())
            .environmentObject(ErrorHandling())
    }
}
