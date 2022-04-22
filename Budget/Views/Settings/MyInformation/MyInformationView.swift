//
//  MyInformationView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-16.
//

import SwiftUI

struct MyInformationView: View {
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var signOutAsGuestPressed: Bool = false
    
    var body: some View {
        Form {
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
