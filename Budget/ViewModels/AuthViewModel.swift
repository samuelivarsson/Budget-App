//
//  AuthViewModel.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-16.
//

import Firebase
import Foundation
import GoogleSignIn
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var state: SignInState = .signedOut
    
    let auth = Auth.auth()
    
    init() {
        self._state = Published(initialValue: auth.currentUser != nil ? .signedIn : .signedOut)
    }
    
    var getState: SignInState {
        return auth.currentUser != nil ? .signedIn : .signedOut
    }
    
    enum SignInState {
        case signedIn
        case signedOut
    }
    
    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        auth.signIn(withEmail: email, password: password) { _, error in
            if let error = error {
                completion(error)
                return
            }
            
            // Success
            completion(nil)
        }
    }
    
    func signIn(completion: @escaping (Error?) -> Void) {
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
                guard let self = self else {
                    let info = "Found unexpected nil when extracting self in signIn in AuthViewModel (1)"
                    print(info)
                    completion(ApplicationError.unexpectedNil(info))
                    return
                }
                guard error == nil else {
                    completion(error)
                    return
                }
                
                guard let user = user else {
                    let info = "Found nil when extracting user in signIn in AuthViewModel (1)"
                    completion(ApplicationError.unexpectedNil(info))
                    return
                }
                
                self.authenticateUser(for: user) { error in
                    if let error = error {
                        completion(error)
                        return
                    }

                    // Success
                    completion(nil)
                }
            }
            
            return
        }
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            let info = "Found unexpected nil when extracting clientID in signIn in AuthViewModel"
            completion(ApplicationError.unexpectedNil(info))
            return
        }
            
        let configuration = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = configuration
            
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            let info = "Found unexpected nil when extracting windowScene in signIn in AuthViewModel"
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        guard let rootViewController = windowScene.windows.first?.rootViewController else {
            let info = "Found unexpected nil when extracting rootViewController in signIn in AuthViewModel"
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] signResult, error in
            guard let self = self else {
                let info = "Found unexpected nil when extracting self in signIn in AuthViewModel (2)"
                completion(ApplicationError.unexpectedNil(info))
                return
            }
            if let error = error {
                completion(error)
                return
            }
            
            guard let user = signResult?.user else {
                let info = "Found nil when extracting user in signIn in AuthViewModel (2)"
                completion(ApplicationError.unexpectedNil(info))
                return
            }
                 
            self.authenticateUser(for: user) { error in
                if let error = error {
                    completion(error)
                    return
                }

                // Success
                completion(nil)
            }
        }
    }
    
    private func authenticateUser(for user: GIDGoogleUser, completion: @escaping (Error?) -> Void) {
        guard let idToken = user.idToken else {
            let info = "Found nil when extracting idToken in signIn in AuthViewModel"
            completion(ApplicationError.unexpectedNil(info))
            return
        }
            
        let accessToken = user.accessToken
                        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString, accessToken: accessToken.tokenString)

        // Use the credential to authenticate with Firebase
            
        auth.signIn(with: credential) { _, error in
            if let error = error {
                completion(error)
                return
            }

            // Success
            completion(nil)
        }
    }
    
    func signInAnonymously(completion: @escaping (Error?) -> Void) {
        auth.signInAnonymously { _, error in
            if let error = error {
                completion(error)
                return
            }
            
            // Success
            completion(nil)
        }
    }
    
    func signUp(email: String, password: String, name: String, completion: @escaping (Error?) -> Void) {
        auth.createUser(withEmail: email, password: password) { [weak self] _, error in
            guard let self = self else {
                let info = "Found unexpected nil when extracting self in signUp in AuthViewModel (1)"
                print(info)
                completion(ApplicationError.unexpectedNil(info))
                return
            }
            if let error = error {
                completion(error)
                return
            }
            
            // Success
            DispatchQueue.main.async {
                guard let changeRequest = self.auth.currentUser?.createProfileChangeRequest() else {
                    completion(AccountError.notSignedIn)
                    return
                }
                changeRequest.displayName = name
                changeRequest.commitChanges { error in
                    if let error = error {
                        completion(error)
                        return
                    }
                    
                    // Success
                    completion(nil)
                }
            }
        }
    }
    
    func signOut(completion: @escaping (Error?) -> Void) {
        GIDSignIn.sharedInstance.signOut()
        
        do {
            try auth.signOut()
            
            DispatchQueue.main.async {
                self.state = .signedOut
            }
            completion(nil)
        } catch {
            print(error.localizedDescription)
            completion(error)
        }
    }
    
    // QTODO - Update password
    // QTODO - Password reset
    // QTODO - Delete user
    // QTODO - If user is updated elsewhere, the change isn't seen until re-login
    // https://firebase.google.com/docs/auth/ios/manage-users
}
