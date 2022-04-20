//
//  FriendView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-19.
//

import SwiftUI
import Combine
import Firebase

struct FriendView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    @EnvironmentObject private var errorHandling: ErrorHandling
    
//    let db = Firestore.firestore()
    
    @State private var email: String = ""
    @State private var name: String = ""
    @State private var phone: String = ""
    
    var add: Bool
    
    init(add: Bool = false) {
        self.add = add
    }
    
    init(friend: Friend) {
        self.add = false
        self._name = State(initialValue: friend.name ?? "")
        self._phone = State(initialValue: friend.phone ?? "")
    }
    
    var body: some View {
        Form {
            if add {
                Section("addUserByEmail") {
                    emailView
                    Button("add") {
                        addUserAsFriend()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            
            Section(add ? "addFriendManually" : "editFriend") {
                nameView
                phoneView
                if !add {
                    NavigationLink {
                        ConnectFriendView()
                    } label: {
                        Text("email")
                    }
                }
                Button(add ? "add" : "apply") {
                    // TODO - Edit friend instead of creating new
                    addFriend()
                    presentationMode.wrappedValue.dismiss()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle(add ? "addFriend" : "editFriend")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var emailView: some View {
        HStack(spacing: 30) {
            Text("email")
            TextField("email", text: $email, prompt: Text("userEmail"))
                .multilineTextAlignment(.trailing)
        }
    }
    
    private var nameView: some View {
        HStack(spacing: 30) {
            Text("name")
            TextField("name", text: $name, prompt: Text("friendsName"))
                .multilineTextAlignment(.trailing)
        }
    }
    
    private var phoneView: some View {
        HStack(spacing: 30) {
            Text("phone")
            TextField("phone", text: $phone, prompt: Text("friendsPhone"))
                .multilineTextAlignment(.trailing)
        }
    }
    
    private func addUserAsFriend() {
        // TODO
    }
    
    private func addFriend() {
        withAnimation {
            let newFriend = Friend(context: viewContext)
            newFriend.id = UUID()
            newFriend.name = name
            newFriend.phone = phone
            
            do {
                try viewContext.save()
            } catch {
                errorHandling.handle(error: error)
            }
        }
    }
}

struct FriendView_Previews: PreviewProvider {
    static var previews: some View {
        FriendView()
            .environmentObject(ErrorHandling())
    }
}
