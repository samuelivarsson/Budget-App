//
//  Transaction2.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-09-18.
//

import Firebase
import FirebaseFirestoreSwift
import Foundation

struct Transaction: Identifiable, Codable {
    @DocumentID var documentId: String?
    var totalAmount: Double
    var category: TransactionCategory
    var date: Date
    var desc: String
    var creator: String
    var payer: String
    var participants: [Participant]
    var participantIds: [String] = .init()
    var type: TransactionType
    var splitEvenly: Bool = true

    var id: String { documentId ?? "" }
    
    func getImageName() -> String {
        switch type {
        case .expense:
            return "arrow.down.square.fill"
        case .income:
            return "arrow.up.square.fill"
        case .saving:
            return "circle.circle"
        }
    }
    
    func delete(completion: @escaping (Error?) -> Void) {
        guard let transactionID = documentId else {
            completion(ApplicationError.unexpectedNil("Found nil when extracting id in delete in Transaction"))
            return
        }
        
        let db = Firestore.firestore()
        db.collection("Transactions").document(transactionID).delete { error in
            if let error = error {
                completion(error)
                return
            }
            
            // Success
            completion(nil)
        }
    }
    
    func getShare(user: User) -> Double {
        for participant in participants {
            if participant.userId == user.id {
                return participant.amount
            }
        }
        
        return 0.0
    }
}
