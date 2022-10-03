//
//  SettingsView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-12.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject private var storageViewModel: StorageViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    NavigationLink {
                        MyInformationView()
                    } label: {
                        HStack(spacing: 20) {
                            ProfilePicture(uiImage: storageViewModel.profilePicture, failImage: Image(systemName: "person.circle"))
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading) {
                                let userName = authViewModel.auth.currentUser?.displayName ?? "Guest"
                                Text(userName).font(.headline)
                                Text("emailNamePhone").font(.subheadline)
                            }
                        }
                    }
                    .frame(height: 60)
                }
                
                Section {
                    SettingsRowsView()
                }
            }
            .navigationTitle("settings")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AuthViewModel())
            .environmentObject(ErrorHandling())
    }
}
