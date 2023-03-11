//
//  StorageViewModel.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-05-10.
//

import Foundation
import Firebase
import SwiftUI

class StorageViewModel: ObservableObject {
    @Published var profilePicture: UIImage?
    
    let auth = Auth.auth()
    
    init() {
        if self.auth.currentUser != nil {
            self.fetchProfilePicture() { error in
                if let error = error {
                    print("Error when initializing StorageViewModel: \(error.localizedDescription)")
                    return
                }
                
                // Success
                print("Successfully set profilePicture at init in StorageViewModel")
            }
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
                
                // Success
                print("Successfully changed photo URL")
                self.fetchProfilePicture() { error in
                    if let error = error {
                        completion(error)
                        return
                    }
                    
                    // Success
                    print("Successfully set profile picture")
                    completion(nil)
                }
            }
        }
    }
    
    func fetchProfilePicture(completion: @escaping (Error?) -> Void) {
        guard let user = auth.currentUser else {
            let info = "Found nil when extracting user in setProfilePicture in StorageViewModel"
            print(info)
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        guard let url = user.photoURL else {
            print("Error in fetchProfilePicture in StorageViewModel (1): \n\(AccountError.noPhotoURL.localizedDescription)")
            completion(nil)
            return
        }
        
        Utility.getImageFromURL(url: url) { [weak self] uiImage, error in
            guard let self = self else {
                let info = "Found nil when extracting self in setProfilePicture in StorageViewModel"
                print(info)
                completion(ApplicationError.unexpectedNil(info))
                return
            }
            if let error = error {
                print("Error in fetchProfilePicture in StorageViewModel (2): \n\(error.localizedDescription)")
                completion(error)
                return
            }
            
            // Success
            DispatchQueue.main.async {
                self.profilePicture = uiImage
                completion(nil)
            }
        }
    }
}
