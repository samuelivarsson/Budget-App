//
//  SignInView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-16.
//

import SwiftUI

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Text("signIn").font(.largeTitle).padding(.bottom, 40)
        
            // Sign in with Google
            Button {
                viewModel.signIn()
            } label: {
                HStack {
                    Image("google-logo")
                    Spacer()
                    Text("signInWithGoogle")
                    Spacer()
                }
                .font(Font.system(size: 14).bold())
                .foregroundColor(.white)
                .frame(width: 300, height: 48)
                .background(Color(hex: "#4285F4"))
                .cornerRadius(5)
            }
            
            // Sign in anonymously
            Button {
                viewModel.signInAnonymously()
            } label: {
                HStack {
                    Image(systemName: "person").padding()
                    Spacer()
                    Text("signInAsGuest")
                    Spacer()
                } // TESTA MED LABEL
                .font(Font.system(size: 14).bold())
                .foregroundColor(.white)
                .frame(width: 300, height: 48)
                .background(Color.secondary)
                .cornerRadius(5)
            }
            
            HStack {
                VStack { Divider() }
                Text("or").foregroundColor(.secondary)
                VStack { Divider() }
            }
            
            VStack {
                TextField("email", text: $email)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground))

                SecureField("password", text: $password)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                
                Button {
                    guard !email.isEmpty else {
                        print("pleaseEnterEmail")
                        return
                    }
                    guard !password.isEmpty else {
                        print("pleaseEnterPassword")
                        return
                    }
                    
                    viewModel.signIn(email: email, password: password)
                } label: {
                    Text("signIn")
                        .font(Font.system(size: 14).bold())
                        .foregroundColor(.white)
                        .frame(width: 300, height: 48)
                        .background(Color(hex: "#4285F4"))
                        .cornerRadius(5)
                }
                .padding(.top, 20)
            }
            
            Divider()
            
            HStack {
                Text("noAccount")
                    .foregroundColor(.secondary)
                Button("register") {
                    
                }
            }
        }
        .frame(width: 300)
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
        SignInView()
            .preferredColorScheme(.dark)
    }
}
