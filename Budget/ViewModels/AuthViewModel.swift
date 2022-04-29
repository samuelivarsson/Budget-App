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
    
    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        auth.signIn(withEmail: email, password: password) { _, error in
            completion(error)
            guard error == nil else { return }
            
            // Success
            DispatchQueue.main.async {
                self.state = .signedIn
            }
        }
    }
    
    func signIn(completion: @escaping (Error?) -> Void) {
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
                guard error == nil else {
                    completion(error)
                    return
                }
                guard let self = self else { return }
                self.authenticateUser(for: user) { error in
                    completion(error)
                }
            }
        } else {
            guard let clientID = FirebaseApp.app()?.options.clientID else { return }
            
            let configuration = GIDConfiguration(clientID: clientID)
            
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            guard let rootViewController = windowScene.windows.first?.rootViewController else { return }
            
            GIDSignIn.sharedInstance.signIn(with: configuration, presenting: rootViewController) { [weak self] user, error in
                guard error == nil else {
                    completion(error)
                    return
                }
                guard let self = self else { return }
                
                self.authenticateUser(for: user) { error in
                    completion(error)
                }
            }
        }
    }
    
    private func authenticateUser(for user: GIDGoogleUser?, completion: @escaping (Error?) -> Void) {
        guard let authentication = user?.authentication, let idToken = authentication.idToken else { return }
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken)
        
        auth.signIn(with: credential) { [weak self] _, error in
            completion(error)
            guard let self = self else { return }
            guard error == nil else { return }
            
            self.state = .signedIn
        }
    }
    
    func signInAnonymously(completion: @escaping (Error?) -> Void) {
        auth.signInAnonymously { [weak self] authResult, error in
            completion(error)
            guard let self = self else { return }
            guard error == nil else { return }
            
            // Success
            DispatchQueue.main.async {
                self.state = .signedIn
            }
        }
    }
    
    func signUp(email: String, password: String, name: String, completion: @escaping (Error?) -> Void) {
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            completion(error)
            guard let self = self else { return }
            guard error == nil else { return }
            
            // Success
            DispatchQueue.main.async {
                guard let changeRequest = self.auth.currentUser?.createProfileChangeRequest() else {
                    completion(AccountError.notSignedIn)
                    return
                }
                changeRequest.displayName = name
                changeRequest.commitChanges { [weak self] error in
                    completion(error)
                    guard error == nil else { return }
                    guard let self = self else { return }
                    
                    // Success
                    DispatchQueue.main.async {
                        self.state = .signedIn
                    }
                }
            }
        }
    }
    
    func signOut(completion: @escaping (Error?) -> Void) {
        GIDSignIn.sharedInstance.signOut()
        
        do {
            try auth.signOut()
            
            state = .signedOut
            completion(nil)
        } catch {
            print(error.localizedDescription)
            completion(error)
        }
    }
    
    func changeProfilePicture(url: URL, completion: @escaping (Error?) -> Void) {
        if let changeRequest = auth.currentUser?.createProfileChangeRequest() {
            changeRequest.photoURL = url
            changeRequest.commitChanges { error in
                if let error = error {
                    completion(error)
                    return
                }
                completion(nil)
            }
        }
    }
}
