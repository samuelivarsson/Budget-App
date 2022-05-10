//
//  FriendsView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-19.
//

import SwiftUI

struct FriendsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var fsViewModel: FirestoreViewModel

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Friend.name, ascending: true)],
        animation: .default)
    private var friends: FetchedResults<Friend>
    
    var body: some View {
        Form {
            ForEach(friends) { friend in
                Section {
                    NavigationLink {
                        FriendDetailView(friend: friend)
                    } label: {
                        VStack(alignment: .leading) {
                            if let name = friend.name, let phone = friend.phone {
                                // TODO - Format numbers and make it pretty
                                Text(name).fontWeight(.bold)
                                Text(phone)
                            } else {
                                Text("Something went wrong. Code 59")
                            }
                        }
                    }
                    .frame(minHeight: 50)
                    .padding()
                }
            }
            .onDelete(perform: deleteFriends)
        }
        .navigationTitle("friends")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem {
                NavigationLink {
                    AddFriendView()
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
        .onAppear {
            self.updateFriends()
        }
    }
    
    private func deleteFriends(offsets: IndexSet) {
        withAnimation {
            offsets.map { friends[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                errorHandling.handle(error: error)
            }
        }
    }
    
    private func updateFriends() {
        for friend in self.friends {
            guard let email = friend.email else {
                let info = "Found nil when extracting email in onAppear in FriendsView"
                print(info)
                self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
                return
            }
            fsViewModel.getUserFromEmail(email: email) { user, error in
                if let error = error {
                    self.errorHandling.handle(error: error)
                    return
                }
                
                // Success
                guard let user = user else {
                    let info = "Found nil when extracting user in onAppear in FriendsView"
                    print(info)
                    self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
                    return
                }
                if let userName = user["name"] as? String {
                    friend.name = userName
                }
                if let userEmail = user["email"] as? String {
                    friend.email = userEmail
                }
                if let userPhone = user["phone"] as? String {
                    friend.phone = userPhone
                }
                if let userUID = user["uid"] as? String {
                    friend.uid = userUID
                    friend.custom = userUID.isEmpty
                } else {
                    friend.custom = true
                }
                
                do {
                    try self.viewContext.save()
                } catch {
                    self.errorHandling.handle(error: error)
                }
            }
        }
    }
}

struct FriendsView_Previews: PreviewProvider {
    static var previews: some View {
        FriendsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(ErrorHandling())
    }
}
