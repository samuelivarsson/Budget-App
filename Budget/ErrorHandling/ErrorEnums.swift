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

enum AccountError: Error {
    case notSignedIn
}

extension AccountError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return NSLocalizedString("notSignedIn", comment: "Account Error")
        }
    }
}

enum UserError: Error {
    case noUserWithEmail
}

extension UserError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noUserWithEmail:
            return NSLocalizedString("noUserWithEmail", comment: "User Error")
        }
    }
}

enum ApplicationError: Error {
    case unexpectedNil
}

extension ApplicationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unexpectedNil:
            return NSLocalizedString("applicationError", comment: "Application Error")
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
    case addYourself
}

extension InputError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .addYourself:
            return NSLocalizedString("addYourself", comment: "Input Error")
        }
    }
}

