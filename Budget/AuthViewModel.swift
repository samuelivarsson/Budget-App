//
//  AuthViewModel.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-16.
//

import Foundation
import Firebase
import GoogleSignIn

class AuthViewModel: ObservableObject {
    @Published var state: SignInState = .signedOut
    let auth = Auth.auth()
    
    var getState: SignInState {
        return auth.currentUser != nil ? .signedIn : .signedOut
    }
    
    enum SignInState {
        case signedIn
        case signedOut
    }
    
    func signIn(email: String, password: String) {
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            guard result != nil, error == nil else {
                print("Something went wrong when signing in!")
                print(error!.localizedDescription)
                return
            }
            
            // Success
            DispatchQueue.main.async {
                self?.state = .signedIn
            }
        }
    }
    
    func signIn() {
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            GIDSignIn.sharedInstance.restorePreviousSignIn { [unowned self] user, error in
                authenticateUser(for: user, with: error)
            }
        } else {
            guard let clientID = FirebaseApp.app()?.options.clientID else { return }
            
            let configuration = GIDConfiguration(clientID: clientID)
            
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            guard let rootViewController = windowScene.windows.first?.rootViewController else { return }
            
            GIDSignIn.sharedInstance.signIn(with: configuration, presenting: rootViewController) { [unowned self] user, error in
                authenticateUser(for: user, with: error)
            }
        }
    }
    
    private func authenticateUser(for user: GIDGoogleUser?, with error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        guard let authentication = user?.authentication, let idToken = authentication.idToken else { return }
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken)
        
        auth.signIn(with: credential) { [unowned self] (_, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                self.state = .signedIn
            }
        }
    }
    
    func signInAnonymously() {
        auth.signInAnonymously { [weak self] authResult, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            // Success
            DispatchQueue.main.async {
                self?.state = .signedIn
            }
        }
    }
    
    func signUp(email: String, password: String) {
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            guard result != nil, error == nil else {
                print("Something went wrong when signing up!")
                return
            }
            
            // Success
            DispatchQueue.main.async {
                self?.state = .signedIn
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
        }
    }
}
