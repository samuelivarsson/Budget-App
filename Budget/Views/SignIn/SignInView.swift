//
//  SignInView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-16.
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var fsViewModel: FirestoreViewModel
    
    @State private var email = ""
    @State private var password = ""
    
    private var width: CGFloat = 300
    private var height: CGFloat = 48
    private var cornerRadius: CGFloat = 5
    private var googleBlue: Color = Color(hex: "#4285F4")
    private var aboveFont: Font = .footnote
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("signIn").font(.largeTitle).padding(.bottom, 40)
            
                // Sign in with Google
                Button {
                    authViewModel.signIn() { error in
                        if let error = error {
                            self.errorHandling.handle(error: error)
                            return
                        }
                        
                        // Success
                        guard let user = authViewModel.auth.currentUser else {
                            let info = "Couldn't extract uid from user when signing in with google"
                            print(info)
                            self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
                            return
                        }
                        fsViewModel.setUser(user: user) { error in
                            if let error = error {
                                self.errorHandling.handle(error: error)
                                return
                            }
                            
                            // Success
                            print("Successfully updated user in firestore")
                            self.fsViewModel.setPhoneDict(user: user) { error in
                                if let error = error {
                                    self.errorHandling.handle(error: error)
                                    return
                                }
                                
                                // Success
                                print("Successfully updated phone variable")
                            }
                        }
                    }
                } label: {
                    Label {
                        Text("signInWithGoogle")
                        Spacer()
                    } icon: {
                        Image("google-logo")
                    }
                    .font(Font.system(size: 14).bold())
                    .foregroundColor(.white)
                    .frame(width: width, height: height)
                    .background(googleBlue)
                    .cornerRadius(cornerRadius)
                }
                
                // Sign in anonymously
                Button {
                    authViewModel.signInAnonymously() { error in
                        if let error = error {
                            self.errorHandling.handle(error: error)
                            return
                        }
                        
                        // Success
                    }
                } label: {
                    Label {
                        Text("signInAsGuest")
                        Spacer()
                    } icon: {
                        Image(systemName: "person").padding()
                    }
                    .font(Font.system(size: 14).bold())
                    .foregroundColor(.white)
                    .frame(width: width, height: height)
                    .background(Color.secondary)
                    .cornerRadius(cornerRadius)
                }
                
                HStack {
                    VStack { Divider() }
                    Text("or").foregroundColor(.secondary)
                    VStack { Divider() }
                }
                
                VStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("email").font(aboveFont).padding(2)
                        IconTextField(text: $email, imgName: "at", placeHolderText: "email", disableAutocorrection: true, autoCapitalization: .never, keyboardType: .emailAddress)
                            .padding()
                            .background(Color.secondaryBackground)
                            .cornerRadius(cornerRadius)
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        Text("password").font(aboveFont).padding(2)
                        PasswordField(password: $password)
                            .padding()
                            .background(Color.secondaryBackground)
                            .cornerRadius(cornerRadius)
                    }
                    
                    Button {
                        guard !email.isEmpty else {
                            errorHandling.handle(error: InputError.noEmail)
                            return
                        }
                        guard !password.isEmpty else {
                            errorHandling.handle(error: InputError.noPassword)
                            return
                        }
                        
                        authViewModel.signIn(email: email, password: password) { error in
                            if let error = error {
                                self.errorHandling.handle(error: error)
                                return
                            }
                            
                            // Success
                            guard let user = authViewModel.auth.currentUser else {
                                let info = "Couldn't extract uid from user when signing in"
                                print(info)
                                self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
                                return
                            }
                            fsViewModel.setUser(user: user) { error in
                                if let error = error {
                                    self.errorHandling.handle(error: error)
                                    return
                                }
                                
                                // Success
                                print("Successfully updated user in firestore")
                                self.fsViewModel.setPhoneDict(user: user) { error in
                                    if let error = error {
                                        self.errorHandling.handle(error: error)
                                        return
                                    }
                                    
                                    // Success
                                    print("Successfully updated phone dictionary")
                                }
                            }
                        }
                    } label: {
                        Text("signIn")
                            .font(Font.system(size: 14).bold())
                            .foregroundColor(.white)
                            .frame(width: width, height: height)
                            .background(googleBlue)
                            .cornerRadius(cornerRadius)
                    }
                    .padding(.top, 20)
                }
                
                Divider()
                
                HStack {
                    Text("noAccount")
                        .foregroundColor(.secondary)
                    NavigationLink("register") {
                        SignUpView()
                    }
                    .foregroundColor(googleBlue)
                }
                
                Spacer()
            }
            .frame(width: width)
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
            .environmentObject(AuthViewModel())
        SignInView()
            .environmentObject(AuthViewModel())
            .preferredColorScheme(.dark)
    }
}
