//
//  MyInformationView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-16.
//

import SwiftUI

struct MyInformationView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    
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
        }
        .navigationTitle("myInformation")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MyInformationView_Previews: PreviewProvider {
    static var previews: some View {
        MyInformationView()
            .environmentObject(AuthViewModel())
    }
}
