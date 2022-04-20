//
//  MyInformationView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-16.
//

import SwiftUI

struct MyInformationView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    @State private var signOutAsGuestPressed: Bool = false
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("email")
                    Spacer()
                    let email = viewModel.auth.currentUser?.email ?? "-"
                    Text(email).foregroundColor(.secondary)
                }
                
                HStack {
                    Text("name")
                    Spacer()
                    let userName = viewModel.auth.currentUser?.displayName ?? "Guest"
                    Text(userName).foregroundColor(.secondary)
                }
                
                HStack {
                    Text("phone")
                    Spacer()
                    let phone = viewModel.auth.currentUser?.phoneNumber ?? ""
                    NavigationLink {
                        EditPhoneView()
                    } label: {
                        Text(phone).foregroundColor(.secondary)
                    }
                }
            }
            
            Section {
                Button(role: .destructive) {
                    guard let user = viewModel.auth.currentUser else { return }
                    if user.isAnonymous {
                        signOutAsGuestPressed = true
                        return
                    }
                    viewModel.signOut()
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
                viewModel.signOut()
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
