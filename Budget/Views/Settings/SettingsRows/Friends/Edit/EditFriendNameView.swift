//
//  EditFriendNameView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-20.
//

import SwiftUI

struct EditFriendNameView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    @EnvironmentObject private var errorHandling: ErrorHandling
    
    @State private var name: String = ""
    
    private var friend: Friend
    
    init(friend: Friend) {
        self.friend = friend
        self._name = State(initialValue: friend.name ?? "")
    }
    
    var body: some View {
        Form {
            Section("name") {
                TextField("name", text: $name, prompt: Text("friendsName"))
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
        .navigationTitle("editFriendName")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func editFriend() {
        friend.name = name
        
        do {
            try viewContext.save()
        } catch {
            errorHandling.handle(error: error)
        }
    }
}

struct EditFriendNameView_Previews: PreviewProvider {
    static var previews: some View {
        EditFriendNameView(friend: Friend())
            .environmentObject(ErrorHandling())
    }
}
