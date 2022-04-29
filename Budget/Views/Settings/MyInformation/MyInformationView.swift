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
                        // TODO - Save image somehow so it doesnt have to load everytime
                        // TODO - Update image in SettingsView and MyInformationView when new picture has been uploaded
                        UserPicture(user: authViewModel.auth.currentUser)
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
                
                HStack {
                    Text("phone")
                    Spacer()
                    let phone = authViewModel.auth.currentUser?.phoneNumber ?? ""
                    NavigationLink {
                        EditPhoneView()
                    } label: {
                        Text(phone).foregroundColor(.secondary)
                    }
                }
            }
            
            Section {
                Button(role: .destructive) {
                    guard let user = authViewModel.auth.currentUser else { return }
                    if user.isAnonymous {
                        signOutAsGuestPressed = true
                        return
                    }
                    authViewModel.signOut() { error in
                        if let error = error {
                            errorHandling.handle(error: error)
                        }
                    }
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
                    }
                }
            }
        } message: {
            Text("signOutAsGuestImplication")
        }
    }
}

struct MyInformationView_Previews: PreviewProvider {
    static var previews: some View {
        MyInformationView()
            .environmentObject(AuthViewModel())
    }
}
