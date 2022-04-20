//
//  ConnectFriendView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-19.
//

import SwiftUI

struct ConnectFriendView: View {
    @State private var email: String = ""
    
    var body: some View {
        Form {
            Section("email") {
                TextField("email", text: $email, prompt: Text("userEmail"))
            }
            
            HStack {
                Spacer()
                Button("apply") {
                    addUserAsFriendAndConnect()
                }
                Spacer()
            }
        }
        .navigationTitle("connectFriend")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func addUserAsFriendAndConnect() {
        // TODO
    }
}

struct ConnectFriendView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectFriendView()
    }
}
