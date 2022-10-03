//
//  EditPhoneView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-17.
//

import SwiftUI

struct EditPhoneView: View {
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var fsViewModel: FirestoreViewModel
    
    @State private var phoneText: String = ""
    @State private var isLoading = false
    
    var body: some View {
        Form {
            Section {
                // QTODO - Add land code chooser
                TextField("yourPhone", text: $phoneText).keyboardType(.phonePad)
            }
            
            Button {
                self.updatePhone()
            } label: {
                HStack {
                    Spacer()
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("apply")
                    }
                    Spacer()
                }
            }
        }
        .navigationTitle("editPhone")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard let user = authViewModel.auth.currentUser else {
                let info = "Found nil when extracting user in onAppear in EditPhoneView"
                print(info)
                self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
                return
            }
            guard let phone = self.fsViewModel.phone[user.uid] else {
                let info = "Found nil when extracting phone in onAppear in EditPhoneView"
                print(info)
                self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
                return
            }
            
            self.phoneText = phone
        }
    }
    
    private func updatePhone() {
        guard phoneText.count > 9 else {
            self.errorHandling.handle(error: InputError.phoneTooShort)
            return
        }
        
        self.isLoading = true
        self.fsViewModel.updatePhone(with: phoneText, user: authViewModel.auth.currentUser) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
             // Success
            self.isLoading = false
            self.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct EditPhoneView_Previews: PreviewProvider {
    static var previews: some View {
        EditPhoneView()
            .environmentObject(AuthViewModel())
    }
}
