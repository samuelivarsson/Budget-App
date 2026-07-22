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
    var splitOption: SplitOption = .standard

    var id: String { documentId ?? UUID().uuidString }
    
    enum CodingKeys: String, CodingKey {
        case documentId
        case totalAmount
        case category
        case date
        case desc
        case creatorId
        case creatorName
        case payerId
        case payerName
        case participants
        case participantIds
        case type
        case splitOption = "splitEvenly"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _documentId = try container.decode(DocumentID<String>.self, forKey: .documentId)
        totalAmount = try container.decode(Double.self, forKey: .totalAmount)
        category = try container.decode(TransactionCategory.self, forKey: .category)
        date = try container.decode(Date.self, forKey: .date)
        desc = try container.decode(String.self, forKey: .desc)
        creatorId = try container.decode(String.self, forKey: .creatorId)
        creatorName = try container.decode(String.self, forKey: .creatorName)
        payerId = try container.decode(String.self, forKey: .payerId)
        payerName = try container.decode(String.self, forKey: .payerName)
        participants = try container.decode([Participant].self, forKey: .participants)
        participantIds = try container.decode([String].self, forKey: .participantIds)
        type = try container.decode(TransactionType.self, forKey: .type)
        
        if let splitOptionInt = try? container.decode(Int16.self, forKey: .splitOption),
           let splitOption = SplitOption(rawValue: splitOptionInt)
        {
            self.splitOption = splitOption
        } else if let _ = try? container.decode(Bool.self, forKey: .splitOption) {
            splitOption = .standard
        } else {
            splitOption = .standard // Default value or other error handling
        }
    }
    
    init(totalAmount: Double, category: TransactionCategory, date: Date, desc: String, creatorId: String, creatorName: String, payerId: String, payerName: String, participants: [Participant], type: TransactionType) {
        self.totalAmount = totalAmount
        self.category = category
        self.date = date
        self.desc = desc
        self.creatorId = creatorId
        self.creatorName = creatorName
        self.payerId = payerId
        self.payerName = payerName
        self.participants = participants
        self.type = type
    }

    static func getDummyTransaction(category: TransactionCategory = TransactionCategory.getDummyCategory()) -> Transaction {
        return Transaction(totalAmount: 0, category: category, date: Date(), desc: "", creatorId: "", creatorName: "", payerId: "", payerName: "", participants: [], type: .expense)
    }
    
    func getImageName() -> String {
        switch type {
        case .expense:
            return "arrow.down.square.fill"
        case .income:
            return "arrow.up.square.fill"
        case .transfer:
            return "circle.circle"
        }
    }
    
    func getImageColor() -> Color {
        switch type {
        case .expense:
            return .red
        case .income:
            return .green
        case .transfer:
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
    
    /// The effective category for a given user, resolved against their budget.
    ///
    /// Priority:
    /// 1. The user's own participant category, if they've set one; else the
    ///    transaction's (creator's) category.
    /// 2. Match it to the user's budget by id, then by name.
    /// 3. If nothing matches, fall back to the category marked as "uses the rest"
    ///    (of the same type), else the first category of that type — so a friend's
    ///    category that the user doesn't have still gets counted somewhere.
    func categoryForUser(userId: String, budget: Budget) -> TransactionCategory {
        let target: TransactionCategory
        if let participant = participants.first(where: { $0.userId == userId }),
           let ownCategory = participant.category {
            target = ownCategory
        } else {
            target = self.category
        }

        // 1. Exact id match — robust to two categories sharing a name.
        if let byId = budget.transactionCategories.first(where: { $0.id == target.id }) {
            return byId
        }
        // 2. Name match of the SAME type, whitespace/Unicode/case-insensitive.
        //    The type check matters when a name exists for more than one type
        //    (e.g. both an expense and an income "Övrigt") — otherwise a friend's
        //    income "Övrigt" could resolve to your expense "Övrigt".
        if let byName = budget.transactionCategories.first(where: {
            $0.type == target.type && $0.name.matchesCategoryName(target.name)
        }) {
            return byName
        }
        // 3. No match: use the "uses the rest" category (same type), else the first
        //    category of that type.
        let sameType = budget.transactionCategories.filter { $0.type == target.type }
        if let rest = sameType.first(where: { $0.id == budget.transactionCategoryThatUsesRest }) {
            return rest
        }
        if let first = sameType.first {
            return first
        }
        return target
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
            if participant.userId == payerId {
                return participant.userName
            }
        }
        
        return ""
    }

    func isMine(userId: String) -> Bool {
        return creatorId == userId
    }
    
    func isMyCategory(user: User) -> Bool {
        return user.budget.transactionCategories.contains(where: { $0.id == self.category.id })
    }
}

private extension String {
    /// Compares category names ignoring surrounding whitespace, Unicode
    /// normalization form and case — so a name like "Övrigt" matches regardless of
    /// stray spaces or whether the "Ö" is precomposed or "O" + combining diaeresis.
    func matchesCategoryName(_ other: String) -> Bool {
        func normalized(_ s: String) -> String {
            s.trimmingCharacters(in: .whitespacesAndNewlines).precomposedStringWithCanonicalMapping
        }
        return normalized(self).caseInsensitiveCompare(normalized(other)) == .orderedSame
    }
}
