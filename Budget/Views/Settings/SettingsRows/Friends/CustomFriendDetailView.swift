//
//  CustomFriendDetailView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-10-06.
//

import SwiftUI

struct CustomFriendDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    
    private var friend: CustomFriend
    
    init(friend: CustomFriend) {
        self.friend = friend
    }
    
    var body: some View {
        Form {
            HStack {
                Spacer()
                VStack {
                    Image(systemName: "person.circle")
                        .resizable()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                    
                    Text(self.friend.name)
                        .font(.headline)
                }
                Spacer()
            }
            .listRowBackground(colorScheme == .dark ? Color.background : Color.secondaryBackground)

            Section {
                NavigationLink {
                    EditFriendNameView(customFriend: self.friend)
                } label: {
                    HStack {
                        Text("name")
                        Spacer()
                        Text(self.friend.name)
                    }
                }
                NavigationLink {
                    EditFriendPhoneView(customFriend: self.friend)
                } label: {
                    HStack {
                        Text("phone")
                        Spacer()
                        Text(self.friend.phone)
                    }
                }
            } footer: {
                Text("onlyNonCustom")
            }
        }
        .navigationTitle("editFriend")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CustomFriendDetailView_Previews: PreviewProvider {
    static var previews: some View {
        CustomFriendDetailView(friend: CustomFriend(name: "", phone: ""))
    }
}
