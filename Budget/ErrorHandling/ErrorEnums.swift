//
//  ErrorEnums.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-18.
//

import Foundation

enum NetworkError: Error {
    case imageFetch
    case test
}

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .imageFetch:
            return NSLocalizedString("imageFetchError", comment: "Network Error")
        case .test:
            return NSLocalizedString("signUp", comment: "Network Error")
        }
    }

    public var failureReason: String? {
        switch self {
        case .imageFetch:
            return NSLocalizedString("networkProblem", comment: "Network Error")
        case .test:
            return NSLocalizedString("signUp", comment: "Network Error")
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .imageFetch:
            return NSLocalizedString("checkConnectionTryAgain", comment: "Network Error")
        case .test:
            return NSLocalizedString("signUp", comment: "Network Error")
        }
    }
}

enum FirestoreError: Error {
    case documentNotExist
}

extension FirestoreError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .documentNotExist:
            return NSLocalizedString("documentNotExist", comment: "Firestore Error")
        }
    }
}

enum AccountError: Error {
    case notSignedIn
    case noPhotoURL
}

extension AccountError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return NSLocalizedString("notSignedIn", comment: "Account Error")
        case .noPhotoURL:
            return NSLocalizedString("noPhotoURL", comment: "Account Error")
        }
    }
}

enum UserError: Error {
    case noUserWithEmail
    case noAccountsYet
    case accountIsUsedByAmount
}

extension UserError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noUserWithEmail:
            return NSLocalizedString("noUserWithEmail", comment: "User Error")
        case .noAccountsYet:
            return NSLocalizedString("noAccountsYet", comment: "User Error")
        case .accountIsUsedByAmount:
            return NSLocalizedString("accountIsUsedByAmount", comment: "User Error")
        }
    }
}

enum ApplicationError: Error {
    case unexpectedNil(String)
}

extension ApplicationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unexpectedNil(let info):
            return NSLocalizedString("applicationError", comment: "Application Error") + ": \(info)"
        }
    }

    public var failureReason: String? {
        switch self {
        case .unexpectedNil:
            return NSLocalizedString("unexpectedNil", comment: "Application Error")
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .unexpectedNil:
            return NSLocalizedString("pleaseTryAgain", comment: "Application Error")
        }
    }
}

enum InputError: Error {
    case noEmail
    case noPassword
    case noName
    case noPhone
    case phoneTooShort
    case addYourself
    case userIsAlreadyFriend
    case totalAmountMisMatch
    case transactionCategoryAmountsAddsUpToMoreThanRemaining
    case deleteTransactionCreatedBySomeoneElse
}

extension InputError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noEmail:
            return NSLocalizedString("pleaseEnterEmail", comment: "Input Error")
        case .noPassword:
            return NSLocalizedString("pleaseEnterPassword", comment: "Input Error")
        case .noName:
            return NSLocalizedString("pleaseEnterName", comment: "Input Error")
        case .noPhone:
            return NSLocalizedString("pleaseEnterPhone", comment: "Input Error")
        case .phoneTooShort:
            return NSLocalizedString("phoneTooShort", comment: "Input Error")
        case .addYourself:
            return NSLocalizedString("addYourself", comment: "Input Error")
        case .userIsAlreadyFriend:
            return NSLocalizedString("userIsAlreadyFriend", comment: "Input Error")
        case .totalAmountMisMatch:
            return NSLocalizedString("totalAmountMisMatch", comment: "Input Error")
        case .transactionCategoryAmountsAddsUpToMoreThanRemaining:
            return NSLocalizedString("transactionCategoryAmountsAddsUpToMoreThanRemaining", comment: "Input Error")
        case .deleteTransactionCreatedBySomeoneElse:
            return NSLocalizedString("deleteTransactionCreatedBySomeoneElse", comment: "Input Error")
        }
    }
}
