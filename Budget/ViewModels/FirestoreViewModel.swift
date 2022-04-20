//
//  FirestoreViewModel.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-20.
//

import Foundation
import Firebase

class FirestoreViewModel: ObservableObject {
    @Published var list = []
    
    let db = Firestore.firestore()
    
    func getUserFromEmail(email: String, completion: @escaping ([String: Any]?, Error?) -> Void) {
        db.collection("Users").whereField("email", isEqualTo: email.lowercased()).getDocuments() { snapshot, error in
                if let error = error {
                    print("Error getting documents: \(error)")
                    completion(nil, error)
                    return
                }
                guard let snapshot = snapshot else {
                    completion(nil, ApplicationError.unexpectedNil)
                    return
                }
                guard !snapshot.documents.isEmpty else {
                    completion(nil, UserError.noUserWithEmail)
                    return
                }
                
                completion(snapshot.documents[0].data(), nil)
        }
    }
}
