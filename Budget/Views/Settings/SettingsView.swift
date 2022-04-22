//
//  SettingsView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-12.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    NavigationLink {
                        MyInformationView()
                    } label: {
                        HStack(spacing: 20) {
                            UserPicture(user: authViewModel.auth.currentUser)
                                .clipShape(Circle())
                                .padding(.vertical, 5)
                            
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
