//
//  FriendsViewModel.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-05-03.
//

import Foundation
import SwiftUI
import FirebaseStorage

class FriendsViewModel: ObservableObject {
    @Published var friendPictures: [String: UIImage] = [:]
    @Published var usersWithNoPicture: [String] = []
    
    func hasNoPicture(uid: String) -> Bool {
        return self.usersWithNoPicture.contains(uid)
    }
    
    func getPicture(uid: String, completion: @escaping (UIImage?, Error?) -> Void) {
        if self.hasNoPicture(uid: uid) {
            completion(nil, nil)
            return
        }
        if let uiImage = self.friendPictures[uid] {
            completion(uiImage, nil)
            return
        }
        
        Utility.getProfilePictureFromUID(uid: uid) { image, error in
            if let error = error {
                guard let error = error as NSError? else {
                    completion(nil, error)
                    return
                }
                
                let code = StorageErrorCode(rawValue: error.code)
                
                switch code {
                case .objectNotFound:
                    // The user has not uploaded a picture
                    print("The user has no picture")
                    self.usersWithNoPicture.append(uid)
                    completion(nil, nil)
                    return
                default:
                    completion(nil, error)
                    return
                }
            }
            
            // Success
            guard let image = image else {
                let info = "Found nil when extracting image in onLoad in FriendDetailView"
                print(info)
                completion(nil, ApplicationError.unexpectedNil(info))
                return
            }
            DispatchQueue.main.async {
                self.friendPictures[uid] = image
            }
            completion(image, nil)
        }
    }
}
