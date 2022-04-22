//
//  EditPhoneView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-17.
//

import SwiftUI

struct EditPhoneView: View {
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var phoneText: String = ""
    
    var body: some View {
        Form {
            Section {
                TextField("yourPhone", text: $phoneText).keyboardType(.phonePad)
            }
            
            Button {
                // TODO - Apply the phone number
                presentationMode.wrappedValue.dismiss()
            } label: {
                HStack {
                    Spacer()
                    Text("apply")
                    Spacer()
                }
            }
        }
        .navigationTitle("editPhone")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EditPhoneView_Previews: PreviewProvider {
    static var previews: some View {
        EditPhoneView()
            .environmentObject(AuthViewModel())
    }
}
