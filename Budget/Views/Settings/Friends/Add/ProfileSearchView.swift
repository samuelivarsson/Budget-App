//
//  ProfileSearchView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-10-09.
//

import SwiftUI

struct ProfileSearchView: View {
    @EnvironmentObject private var errorHandling: ErrorHandling
    @StateObject var usersLookupViewModel = UsersLookupViewModel()
    
    @State var keyword: String = ""
    
    var isInputActive: FocusState<Bool>.Binding
    
    var body: some View {
        let keywordBinding = Binding<String>(
            get: {
                self.keyword
            },
            set: {
                self.keyword = $0
                self.usersLookupViewModel.fetchData(from: self.keyword) { error in
                    if let error = error {
                        self.errorHandling.handle(error: error)
                        return
                    }
                    
                    // Success
                }
            }
        )
        SearchBarView(keyword: keywordBinding, isInputActive: self.isInputActive)
        if self.usersLookupViewModel.queriedUsers.count > 0 {
            ScrollView {
                ForEach(self.usersLookupViewModel.queriedUsers, id: \.documentId) { user in
                    ProfileBarView(user: user)
                        .environmentObject(self.usersLookupViewModel)
                }
            }
            .padding(.top, 10)
        }
    }
}

struct SearchBarView: View {
    @Binding var keyword: String
    
    var isInputActive: FocusState<Bool>.Binding
    
    var body: some View {
        TextField("searchForUser", text: self.$keyword)
            .autocorrectionDisabled(true)
            .focused(self.isInputActive)
    }
}

struct ProfileBarView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var usersLookupViewModel: UsersLookupViewModel
    @EnvironmentObject private var notificationsViewModel: NotificationsViewModel
    
    @State private var addUserLoading: Bool = false
    
    var user: User
    
    var body: some View {
        HStack {
            ProfilePicture(
                uiImage: self.usersLookupViewModel.userPictures[self.user.id],
                failImage: Image(systemName: "person.circle")
            )
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            Text("\(self.user.name)")
            Spacer()
            if self.addUserLoading {
                ProgressView()
            } else {
                if self.userViewModel.isUserFriend(uid: self.user.id) {
                    Image(systemName: "person.fill.checkmark")
                        .frame(maxWidth: 30)
                } else if self.userViewModel.isUserRequested(uid: self.user.id) {
                    Button {
                        self.cancelFriendRequest(friend: self.user)
                    } label: {
                        Image(systemName: "person.fill.questionmark")
                    }
                } else {
                    let (notification, hasUserSentRequest) = self.notificationsViewModel.hasUserSentRequest(uid: self.user.id)
                    if hasUserSentRequest {
                        HStack {
                            Button {
                                self.acceptFriendRequest(notification: notification)
                            } label: {
                                Image(systemName: "checkmark")
                            }
                            Button {
                                self.denyFriendRequest(notification: notification)
                            } label: {
                                Image(systemName: "nosign")
                            }
                        }
                    } else {
                        Button {
                            self.addUser(user: self.user)
                        } label: {
                            Image(systemName: "person.badge.plus")
                        }
                        .frame(maxWidth: 30)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 50)
    }
    
    private func addUser(user: User) {
        let myUser = self.userViewModel.user
        // You can't add yourself as friend
        guard user.id != myUser.id else {
            self.errorHandling.handle(error: InputError.addYourself)
            return
        }
        // A user can only be one of your friends
        guard !self.userViewModel.isUserFriend(uid: user.id) else {
            self.errorHandling.handle(error: InputError.userIsAlreadyFriend)
            return
        }
        
        self.addUserLoading = true
        
        self.userViewModel.addFriendRequest(friend: user) { error in
            self.addUserLoading = false
            
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
            self.notificationsViewModel.sendFriendRequest(from: myUser, friend: user, to: user.id) { error in
                if let error = error {
                    self.errorHandling.handle(error: error)
                    return
                }
                
                // Success
            }
        }
    }
    
    private func cancelFriendRequest(friend: User) {
        self.userViewModel.cancelFriendRequest(friend: self.user) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
            self.notificationsViewModel.cancelFriendRequest(friendId: friend.id) { error in
                if let error = error {
                    self.errorHandling.handle(error: error)
                    return
                }
                
                // Success
            }
        }
    }
    
    private func acceptFriendRequest(notification: Notification?) {
        guard let notification = notification else {
            let info = "Found nil when extracting uid in addUser in ProfileSearchView"
            print(info)
            self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
            return
        }
        self.userViewModel.acceptFriendRequest(notification: notification) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
            let myName = self.userViewModel.user.name
            
            self.notificationsViewModel.acceptFriendRequest(notification: notification, friend: user, myName: myName) { error in
                if let error = error {
                    self.errorHandling.handle(error: error)
                    return
                }
                
                // Success
                print("Successfully accepted friend request")
            }
        }
    }
    
    private func denyFriendRequest(notification: Notification?) {
        guard let notification = notification else {
            let info = "Found nil when extracting uid in addUser in ProfileSearchView"
            print(info)
            self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
            return
        }
        self.userViewModel.denyFriendRequest(notification: notification) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
            self.notificationsViewModel.denyFriendRequest(notification: notification, friend: user) { error in
                if let error = error {
                    self.errorHandling.handle(error: error)
                    return
                }
                
                // Success
                print("Successfully denied friend request")
            }
        }
    }
}

//struct ProfileSearchView_Previews: PreviewProvider {
//    static var previews: some View {
//        ProfileSearchView()
//    }
//}
