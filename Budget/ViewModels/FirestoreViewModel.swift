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
    
    var errorHandling: ErrorHandling = ErrorHandling()
    let db = Firestore.firestore()
    
    func getUserFromEmail(email: String, completion: @escaping ([String: Any]?) -> Void) {
        db.collection("Users").whereField("email", isEqualTo: email.lowercased())
            .getDocuments() { [weak self] querySnapshot, err in
                guard let self = self else {
                    ErrorHandling().handle(error: ApplicationError.unexpectedNil)
                    return
                }
                if let err = err {
                    print("Error getting documents: \(err)")
                    self.errorHandling.handle(error: err)
                    completion(nil)
                    return
                }
                guard let querySnapshot = querySnapshot else {
                    self.errorHandling.handle(error: ApplicationError.unexpectedNil)
                    completion(nil)
                    return
                }
                guard !querySnapshot.documents.isEmpty else {
                    self.errorHandling.handle(error: UserError.noUserWithEmail, duration: 5)
                    completion(nil)
                    return
                }
                
                completion(querySnapshot.documents[0].data())
        }
    }
}
