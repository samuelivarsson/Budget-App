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
                return NSLocalizedString("checkConnectionTryAgain", comment: "")
            case .test:
                return NSLocalizedString("signUp", comment: "Network Error")
            }
        }
}

enum AccountError: Error {
    case noUser
}

extension AccountError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noUser:
            return NSLocalizedString("noUser", comment: "Account Error")
        }
    }
}
