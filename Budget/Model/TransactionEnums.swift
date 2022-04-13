//
//  TransactionEnums.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-13.
//

import Foundation

//@objc
//public enum TransactionType: String {
//    case expense = "expense"
//    case income = "income"
//}
//
//@objc
//public enum TransactionCategory: String {
//    // Expenses
//    case food = "food"
//    case fika = "fika"
//    case transportation = "transportation"
//    case other = "other"
//    case savingsAccountPurchase = "savingsAccountPurchase"
//    case groceries = "groceries"
//    case saving = "saving"
//
//    // Incomes
//    case savingsAccount = "savingsAccount"
//    case rounding = "rounding"
//    case swish = "swish"
//    case buffer = "buffer"
//}

@objc
public enum TransactionType: Int16 {
    case expense
    case income
}

@objc
public enum TransactionCategory: Int16 {
    case food
    case fika
    case transportation
}

//func getImageName() -> String {
//    return type == TransactionType.income ? "plus.circle" : "minus.circle"
//}
