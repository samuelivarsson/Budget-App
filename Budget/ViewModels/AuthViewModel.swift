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
    @Published var profilePicture: UIImage?
    
    let auth = Auth.auth()
    
    init() {
        self._state = Published(initialValue: self.auth.currentUser != nil ? .signedIn : .signedOut)
        self.setProfilePicture() { error in
            if let error = error {
                print("Error when initializing AuthViewModel: \(error.localizedDescription)")
                return
            }
            
            // Success
            print("Successfully set profilePicture at init in AuthViewModel")
        }
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
            DispatchQueue.main.async {
                self.state = .signedIn
                self.setProfilePicture() { error in
                    if let error = error {
                        completion(error)
                        return
                    }
                    
                    // Success
                    print("Successfully set profilePicture")
                    completion(nil)
                }
            }
        }
    }
    
    func signIn(completion: @escaping (Error?) -> Void) {
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
                guard let self = self else {
                    completion(ApplicationError.unexpectedNil("Found unexpected nil when extracting self in signIn in AuthViewModel (1)"))
                    return
                }
                guard error == nil else {
                    completion(error)
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
        } else {
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                completion(ApplicationError.unexpectedNil("Found unexpected nil when extracting clientID in signIn in AuthViewModel"))
                return
            }
            
            let configuration = GIDConfiguration(clientID: clientID)
            
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                completion(ApplicationError.unexpectedNil("Found unexpected nil when extracting windowScene in signIn in AuthViewModel"))
                return
            }
            guard let rootViewController = windowScene.windows.first?.rootViewController else {
                completion(ApplicationError.unexpectedNil("Found unexpected nil when extracting rootViewController in signIn in AuthViewModel"))
                return
            }
            
            GIDSignIn.sharedInstance.signIn(with: configuration, presenting: rootViewController) { [weak self] user, error in
                guard let self = self else {
                    completion(ApplicationError.unexpectedNil("Found unexpected nil when extracting self in signIn in AuthViewModel (2)"))
                    return
                }
                if let error = error {
                    completion(error)
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
    }
    
    private func authenticateUser(for user: GIDGoogleUser?, completion: @escaping (Error?) -> Void) {
        guard let authentication = user?.authentication, let idToken = authentication.idToken else {
            completion(ApplicationError.unexpectedNil("Found unexpected nil when extracting authentication in authenticateUser in AuthViewModel"))
            return
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken)
        
        auth.signIn(with: credential) { [weak self] _, error in
            guard let self = self else {
                completion(ApplicationError.unexpectedNil("Found unexpected nil when extracting self in authenticateUser in AuthViewModel"))
                return
            }
            if let error = error {
                completion(error)
                return
            }
            
            self.state = .signedIn
            self.setProfilePicture() { error in
                if let error = error {
                    completion(error)
                    return
                }
                
                // Success
                print("Successfully set profilePicture")
                completion(nil)
            }
        }
    }
    
    func signInAnonymously(completion: @escaping (Error?) -> Void) {
        auth.signInAnonymously { [weak self] authResult, error in
            guard let self = self else {
                completion(ApplicationError.unexpectedNil("Found unexpected nil when extracting self in signInAnonymously in AuthViewModel"))
                return	
            }
            if let error = error {
                completion(error)
                return
            }
            
            // Success
            DispatchQueue.main.async {
                self.state = .signedIn
                completion(nil)
            }
        }
    }
    
    func signUp(email: String, password: String, name: String, completion: @escaping (Error?) -> Void) {
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else {
                completion(ApplicationError.unexpectedNil("Found unexpected nil when extracting self in signUp in AuthViewModel (1)"))
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
                changeRequest.commitChanges { [weak self] error in
                    guard let self = self else {
                        completion(ApplicationError.unexpectedNil("Found unexpected nil when extracting self in signUp in AuthViewModel (2)"))
                        return
                    }
                    if let error = error {
                        completion(error)
                        return
                    }
                    
                    // Success
                    DispatchQueue.main.async {
                        self.state = .signedIn
                        self.setProfilePicture() { error in
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
        }
    }
    
    func signOut(completion: @escaping (Error?) -> Void) {
        GIDSignIn.sharedInstance.signOut()
        
        do {
            try auth.signOut()
            
            state = .signedOut
            completion(nil)
            self.profilePicture = nil
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
                self.setProfilePicture() { error in
                    if let error = error {
                        completion(error)
                    }
                }
            }
        }
    }
    
    func setProfilePicture(completion: @escaping (Error?) -> Void) {
        guard let user = auth.currentUser else {
            let info = "Found nil when extracting user in setProfilePicture in AuthViewModel"
            print(info)
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        guard let url = user.photoURL else {
            let info = "Found nil when extracting url in setProfilePicture in AuthViewModel, this can be ignored if the user hasn't uploaded a profile picture yet"
            print(info)
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        
        Utility.getImageFromURL(url: url) { [weak self] uiImage, error in
            guard let self = self else {
                let info = "Found nil when extracting self in setProfilePicture in AuthViewModel"
                print(info)
                completion(ApplicationError.unexpectedNil(info))
                return
            }
            if let error = error {
                print(error.localizedDescription)
                completion(error)
                return
            }
            
            // Success
            self.profilePicture = uiImage
            completion(nil)
        }
    }
    
    // QTODO - Update password
    // QTODO - Password reset
    // QTODO - Delete user
    // QTODO - If user is updated elsewhere, the change isn't seen until re-login
    // https://firebase.google.com/docs/auth/ios/manage-users
    
}
