//
//  UsersLookupViewModel.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-10-06.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseFirestoreSwift

class UsersLookupViewModel: ObservableObject {
    @Published var queriedUsers: [User] = [User]()
    @Published var userPictures: [String: UIImage] = [:]
    
    private let db = Firestore.firestore()
    
    func fetchData(from keyword: String, completion: @escaping (Error?) -> (Void)) {
        self.db.collection("Users").whereField("keywordsForLookup", arrayContains: keyword).getDocuments { querySnapshot, error in
            if let error = error {
                completion(error)
                return
            }
            guard let documents = querySnapshot?.documents else {
                completion(FirestoreError.documentNotExist)
                return
            }
            
            // Success
            self.queriedUsers = documents.compactMap { queryDocumentSnapshot in
                try? queryDocumentSnapshot.data(as: User.self)
            }
            guard let myUser = Auth.auth().currentUser else {
                let info = "Found nil when extracting user in fetchData in UsersLookupViewModel"
                print(info)
                completion(ApplicationError.unexpectedNil(info))
                return
            }
            
            // Should not show ourselves
            self.queriedUsers = self.queriedUsers.filter({ $0.id != myUser.uid })
            
            self.queriedUsers.forEach { user in
                Utility.getProfilePictureFromUID(uid: user.id) { uiImage, error in
                    if let error = error {
                        guard let error = error as NSError? else {
                            completion(error)
                            return
                        }
                        
                        let code = StorageErrorCode(rawValue: error.code)
                        
                        switch code {
                        case .objectNotFound:
                            // The user has not uploaded a picture
                            completion(nil)
                            return
                        default:
                            completion(error)
                            return
                        }
                    }
                    
                    // Success
                    DispatchQueue.main.async {
                        self.userPictures[user.id] = uiImage
                        completion(nil)
                    }
                }
            }
        }
    }
}
