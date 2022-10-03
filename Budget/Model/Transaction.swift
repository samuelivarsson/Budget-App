//
//  Transaction2.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-09-18.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

struct Transaction: Identifiable, Codable {
    @DocumentID var id: String? = UUID().uuidString
    var amount: Double
    var category: String
    var date: Date
    var desc: String
    var creator: String
    var participants: [String]
    var type: TransactionType
    
    func getImageName() -> String {
        switch self.type {
        case .expense:
            return "arrow.down.square.fill"
        case .income:
            return "arrow.up.square.fill"
        case .saving:
            return "circle.circle"
        }
    }
    
    func delete(completion: @escaping (Error?) -> Void) {
        guard let transactionID = self.id else {
            completion(ApplicationError.unexpectedNil("Found nil when extracting id in delete in Transaction"))
            return
        }
        
        let db = Firestore.firestore()
        db.collection("Transactions").document(transactionID).delete() { error in
            if let error = error {
                completion(error)
            }
            
            // Success
            completion(nil)
        }
    }
}
