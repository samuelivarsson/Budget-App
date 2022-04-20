//
//  AuthViewModel.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-16.
//

import Foundation
import Firebase
import GoogleSignIn
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var state: SignInState = .signedOut
    let auth = Auth.auth()
    var errorHandling: ErrorHandling = ErrorHandling()
    
    init() {
        self._state = Published(initialValue: self.auth.currentUser != nil ? .signedIn : .signedOut)
    }
    
    var getState: SignInState {
        return auth.currentUser != nil ? .signedIn : .signedOut
    }
    
    enum SignInState {
        case signedIn
        case signedOut
    }
    
    func signIn(email: String, password: String) {
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                print("Something went wrong when signing in!")
                print(error.localizedDescription)
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
            DispatchQueue.main.async {
                self.state = .signedIn
            }
        }
    }
    
    func signIn() {
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
                guard let self = self else { return }
                self.authenticateUser(for: user, with: error)
            }
        } else {
            guard let clientID = FirebaseApp.app()?.options.clientID else { return }
            
            let configuration = GIDConfiguration(clientID: clientID)
            
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            guard let rootViewController = windowScene.windows.first?.rootViewController else { return }
            
            GIDSignIn.sharedInstance.signIn(with: configuration, presenting: rootViewController) { [weak self] user, error in
                guard let self = self else { return }
                self.authenticateUser(for: user, with: error)
            }
        }
    }
    
    private func authenticateUser(for user: GIDGoogleUser?, with error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            self.errorHandling.handle(error: error)
            return
        }
        
        guard let authentication = user?.authentication, let idToken = authentication.idToken else { return }
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken)
        
        auth.signIn(with: credential) { [weak self] _, error in
            guard let self = self else { return }
            
            if let error = error {
                print(error.localizedDescription)
                self.errorHandling.handle(error: error)
            } else {
                self.state = .signedIn
            }
        }
    }
    
    func signInAnonymously() {
        auth.signInAnonymously { [weak self] authResult, error in
            guard let self = self else { return }
            
            if let error = error {
                print(error.localizedDescription)
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
            DispatchQueue.main.async {
                self.state = .signedIn
            }
        }
    }
    
    func signUp(email: String, password: String, name: String) {
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Something went wrong when signing up!")
                print(error.localizedDescription)
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
            DispatchQueue.main.async {
                guard let changeRequest = self.auth.currentUser?.createProfileChangeRequest() else {
                    self.errorHandling.handle(error: AccountError.notSignedIn)
                    return
                }
                changeRequest.displayName = name
                changeRequest.commitChanges { [weak self] error in
                    guard let self = self else { return }
                    if let error = error {
                        print(error.localizedDescription)
                        self.errorHandling.handle(error: error)
                        return
                    }
                    
                    // Success
                    DispatchQueue.main.async {
                        self.state = .signedIn
                    }
                }
            }
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        
        do {
            try auth.signOut()
            
            state = .signedOut
        } catch {
            print(error.localizedDescription)
            self.errorHandling.handle(error: error)
        }
    }
}
