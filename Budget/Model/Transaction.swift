//
//  Transaction2.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-09-18.
//

import Firebase
import FirebaseFirestoreSwift
import Foundation
import SwiftUI

struct Transaction: Identifiable, Codable {
    @DocumentID var documentId: String?
    var totalAmount: Double
    var category: TransactionCategory
    var date: Date
    var desc: String
    var creatorId: String
    var creatorName: String
    var payerId: String
    var payerName: String
    var participants: [Participant]
    var participantIds: [String] = .init()
    var type: TransactionType
    var splitEvenly: Bool = true

    var id: String { documentId ?? "" }
    
    static func getDummyTransaction(category: TransactionCategory = TransactionCategory.getDummyCategory()) -> Transaction {
        return Transaction(totalAmount: 0, category: category, date: Date(), desc: "", creatorId: "", creatorName: "", payerId: "", payerName: "", participants: [], type: .expense)
    }
    
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
    
    func getImageColor() -> Color {
        switch type {
        case .expense:
            return .red
        case .income:
            return .green
        case .saving:
            return .accentColor
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
    
    func getShare(userId: String) -> Double {
        for participant in participants {
            if participant.userId == userId {
                return participant.amount
            }
        }
        
        return 0.0
    }
    
    func getPayerName() -> String {
        for participant in participants {
            if participant.userId == self.payerId {
                return participant.userName
            }
        }
        
        return ""
    }
}
