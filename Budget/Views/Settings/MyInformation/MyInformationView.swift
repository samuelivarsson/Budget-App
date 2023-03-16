//
//  MyInformationView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-16.
//

import SwiftUI

struct MyInformationView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var fsViewModel: FirestoreViewModel
    @EnvironmentObject private var storageViewModel: StorageViewModel
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var transactionsViewModel: TransactionsViewModel
    @EnvironmentObject private var notificationsViewModel: NotificationsViewModel
    
    @State private var signOutAsGuestPressed: Bool = false
    @State private var isShowPhotoChoices = false
    @State private var isShowPhotoLibrary = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var image = UIImage()
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    ZStack {
                        ProfilePicture(uiImage: storageViewModel.profilePicture, failImage: Image(systemName: "person.circle"))
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button {
                                    isShowPhotoChoices = true
                                } label: {
                                    Image(systemName: "camera")
                                        .padding(5)
                                }
                            }
                        }
                    }
                    .frame(width: 150, height: 150)
                    Spacer()
                }
                .listRowBackground(colorScheme == .dark ? Color.background : Color.secondaryBackground)
                
            }
            
            Section {
                HStack {
                    Text("email")
                    Spacer()
                    let email = authViewModel.auth.currentUser?.email ?? "-"
                    Text(email).foregroundColor(.secondary)
                }
                
                HStack {
                    Text("name")
                    Spacer()
                    let userName = authViewModel.auth.currentUser?.displayName ?? "Guest"
                    Text(userName).foregroundColor(.secondary)
                }
                
                NavigationLink {
                    EditPhoneView()
                } label: {
                    HStack {
                        Text("phone")
                        Spacer()
                        if let user = authViewModel.auth.currentUser {
                            if user.isAnonymous {
                                Text("")
                            } else {
                                if let phone = self.fsViewModel.phone[user.uid] {
                                    Text(phone).foregroundColor(.secondary)
                                } else {
                                    Text("Something went wrong: Code 2001")
                                }
                            }
                        } else {
                            Text("Something went wrong: Code 2002")
                        }
                    }
                }
            }
            
            Section {
                Button(role: .destructive) {
                    signOut()
                } label: {
                    HStack {
                        Spacer()
                        Text("signOut")
                            .textCase(.uppercase)
                            .font(.system(size: 14).weight(.bold))
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("myInformation")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("", isPresented: $isShowPhotoChoices) {
            Button {
                sourceType = .camera
                isShowPhotoLibrary = true
            } label: {
                HStack {
                    Spacer()
                    Text("takePicture")
                    Spacer()
                }
            }
            Button {
                sourceType = .photoLibrary
                isShowPhotoLibrary = true
            } label: {
                HStack {
                    Spacer()
                    Text("choosePicture")
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $isShowPhotoLibrary) {
            ImagePicker(selectedImage: self.$image, sourceType: sourceType)
        }
        .alert("signOut?", isPresented: $signOutAsGuestPressed) {
            Button("signOut", role: .destructive) {
                authViewModel.signOut() { error in
                    if let error = error {
                        errorHandling.handle(error: error)
                        return
                    }
                }
            }
        } message: {
            Text("signOutAsGuestImplication")
        }
    }
    
    private func signOut() {
        guard let user = authViewModel.auth.currentUser else {
            let info = "Found nil when extracting user in signOut in MyInformationView"
            self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
            print(info)
            return
        }
        if user.isAnonymous {
            signOutAsGuestPressed = true
            return
        }
        self.authViewModel.signOut() { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
            DispatchQueue.main.async {
                self.detachListeners()
                self.storageViewModel.profilePicture = nil
            }
        }
    }
    
    private func detachListeners() {
        let listeners = [self.userViewModel.listener, self.transactionsViewModel.listener, self.notificationsViewModel.listener]
        
        listeners.forEach { listener in
            if let listener = listener {
                listener.remove()
            }
        }
    }
}

struct MyInformationView_Previews: PreviewProvider {
    static var previews: some View {
        MyInformationView()
            .environmentObject(AuthViewModel())
    }
}
