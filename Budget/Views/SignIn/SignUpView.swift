//
//  SignUpView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-17.
//

import SwiftUI

struct SignUpView: View {
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    @EnvironmentObject var viewModel: AuthViewModel
    
    private var width: CGFloat = 300
    private var height: CGFloat = 48
    private var cornerRadius: CGFloat = 5
    private var aboveFont: Font = .footnote
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("fullName").font(aboveFont).padding(2)
                IconTextField(text: $fullName, imgName: "person", placeHolderText: "fullName")
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(cornerRadius)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text("email").font(aboveFont).padding(2)
                IconTextField(text: $email, imgName: "at", placeHolderText: "email", disableAutocorrection: true, autoCapitalization: .never)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(cornerRadius)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("password").font(aboveFont).padding(2)
                PasswordField(password: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(cornerRadius)
            }
            
            Button {
                guard !email.isEmpty else {
                    print("pleaseEnterEmail")
                    return
                }
                guard !password.isEmpty else {
                    print("pleaseEnterPassword")
                    return
                }
                guard confirmPassword.contains(password) else {
                    print("passwordNotMatching")
                    return
                }
                
                viewModel.signIn(email: email, password: password)
            } label: {
                Text("signIn")
                    .font(Font.system(size: 14).bold())
                    .foregroundColor(.white)
                    .frame(width: width, height: height)
                    .background(Color(hex: "#4285F4"))
                    .cornerRadius(cornerRadius)
            }
            .padding(.top, 20)
        }
        .frame(width: width)
        .navigationTitle("signUp")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(AuthViewModel())
    }
}
