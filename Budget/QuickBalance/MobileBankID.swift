//
//  MobileBankID.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-25.
//

import Foundation
import SwiftUI

struct MobileBankID {
    private static var _apiVersion = "/v5/"

    static func initAuth(completion: @escaping (MobileBankIDResponse?, Error?) -> Void) {
        DispatchQueue.main.async {
            let body: [String: Any] = ["bankIdOnSameDevice": true]
            QuickBalanceURL.postRequest(apiRequest: self._apiVersion + "identification/bankid/mobile", body: body) { data, response, error in
                let _where = "initAuth in MobileBankID"
                if let error = QuickBalanceURL.checkCompletion(data: data, response: response, error: error, _where: _where) {
                    completion(nil, error)
                    return
                }
                
                guard let data = data else {
                    let info = "Found nil when extracting data in " + _where
                    completion(nil, ApplicationError.unexpectedNil(info))
                    return
                }
                
                // Success
                let mobileBankIdResponse = MobileBankIDResponse(data: data)
                
                guard mobileBankIdResponse.autoStartToken != "" else {
                    let info = "Failed to create MobileBankIDResponse object in " + _where
                    completion(nil, ApplicationError.unexpectedNil(info))
                    return
                }
                
                guard mobileBankIdResponse.status == "USER_SIGN" else {
                    completion(nil, UserError.bankIdNotEnabled)
                    return
                }
                
                completion(mobileBankIdResponse, nil)
            }
        }
    }

    static func verify(completion: @escaping (Error?) -> Void) {
        DispatchQueue.main.async {
            QuickBalanceURL.getRequest(apiRequest: self._apiVersion + "identification/bankid/mobile/verify") { data, response, error in
                let _where = "verify in MobileBankID"
                if let error = QuickBalanceURL.checkCompletion(data: data, response: response, error: error, _where: _where) {
                    completion(error)
                    return
                }
                
                guard let data = data else {
                    let info = "Found nil when extracting data in " + _where
                    completion(ApplicationError.unexpectedNil(info))
                    return
                }
                
                let mobileBankIdResponse = MobileBankIDResponse(data: data)
                
                guard mobileBankIdResponse.status == "COMPLETE" else {
                    completion(UserError.bankIdLoginFailed)
                    return
                }
                
                completion(nil)
            }
        }
    }

    static func profileList(completion: @escaping (Error?) -> Void) {
        DispatchQueue.main.async {
            QuickBalanceURL.getRequest(apiRequest: self._apiVersion + "profile/") { data, response, error in
                let _where = "profileList in MobileBankID"
                if let error = QuickBalanceURL.checkCompletion(data: data, response: response, error: error, _where: _where) {
                    completion(error)
                    return
                }
                
                guard let data = data else {
                    let info = "Found nil when extracting data in " + _where
                    completion(ApplicationError.unexpectedNil(info))
                    return
                }
                
                let profileListResponse = ProfileListResponse(data: data)
                
                let id = profileListResponse.bank.privateProfile.id
                guard !id.isEmpty else {
                    completion(UserError.bankIdLoginFailed)
                    return
                }
                
                QuickBalanceURL.postRequest(apiRequest: self._apiVersion + "profile/" + id, body: .init()) { data, response, error in
                    if let error = QuickBalanceURL.checkCompletion(data: data, response: response, error: error, _where: _where) {
                        completion(error)
                        return
                    }
                    
                    guard let _ = data else {
                        let info = "Found nil when extracting data in " + _where
                        completion(ApplicationError.unexpectedNil(info))
                        return
                    }
                    
                    completion(nil)
                }
            }
        }
    }

    static func quickBalanceAccounts(completion: @escaping (QuickBalanceAccountsResponse?, Error?) -> Void) {
        DispatchQueue.main.async {
            QuickBalanceURL.getRequest(apiRequest: self._apiVersion + "quickbalance/accounts") { data, response, error in
                let _where = "quickBalanceAccounts in MobileBankID"
                if let error = QuickBalanceURL.checkCompletion(data: data, response: response, error: error, _where: _where) {
                    completion(nil, error)
                    return
                }
                
                guard let data = data else {
                    let info = "Found nil when extracting data in " + _where
                    completion(nil, ApplicationError.unexpectedNil(info))
                    return
                }
                
                let quickBalanceAccountsResponse = QuickBalanceAccountsResponse(data: data)
                
                completion(quickBalanceAccountsResponse, nil)
            }
        }
    }

    static func quickBalanceSubscription(quickbalanceSubscriptionID: String, completion: @escaping (QuickBalanceSubscriptionResponse?, Error?) -> Void) {
        DispatchQueue.main.async {
            QuickBalanceURL.postRequest(apiRequest: self._apiVersion + "quickbalance/subscription/" + quickbalanceSubscriptionID, body: [:]) { data, response, error in
                let _where = "quickBalanceSunbscription in MobileBankID"
                if let error = QuickBalanceURL.checkCompletion(data: data, response: response, error: error, _where: _where) {
                    completion(nil, error)
                    return
                }
                
                guard let data = data else {
                    let info = "Found nil when extracting data in " + _where
                    completion(nil, ApplicationError.unexpectedNil(info))
                    return
                }
                
                let quickBalanceSubscriptionResponse = QuickBalanceSubscriptionResponse(data: data)
                
                completion(quickBalanceSubscriptionResponse, nil)
            }
        }
    }
    
    static func quickBalance(subscriptionId: String, completion: @escaping (QuickBalanceResponse?, Error?) -> Void) {
        DispatchQueue.main.async {
            QuickBalanceURL.getRequest(apiRequest: self._apiVersion + "quickbalance/" + subscriptionId) { data, response, error in
                let _where = "quickBalance in MobileBankID"
                if let error = QuickBalanceURL.checkCompletion(data: data, response: response, error: error, _where: _where) {
                    completion(nil, error)
                    return
                }
                
                guard let data = data else {
                    let info = "Found nil when extracting data in " + _where
                    completion(nil, ApplicationError.unexpectedNil(info))
                    return
                }
                
                let quickBalanceResponse = QuickBalanceResponse(data: data)
                
                completion(quickBalanceResponse, nil)
            }
        }
    }
    
    static func terminate(completion: @escaping (Error?) -> Void) {
        DispatchQueue.main.async {
            QuickBalanceURL.putRequest(apiRequest: self._apiVersion + "identification/logout") { data, response, error in
                let _where = "terminate in MobileBankID"
                if let error = QuickBalanceURL.checkCompletion(data: data, response: response, error: error, _where: _where) {
                    completion(error)
                    return
                }
                
                completion(nil)
            }
        }
    }

    static func goNext(mobileBankIdResponse: MobileBankIDResponse, completion: @escaping (MobileBankIDResponse?, Error?) -> Void) {
        DispatchQueue.main.async {
            let links = mobileBankIdResponse.links
            switch links.getHTTPMethod() {
            case .get:
                print("1")
                print(mobileBankIdResponse)
                print("2")
                QuickBalanceURL.getRequest(apiRequest: links.uri) { data, response, error in
                    let _where = "goNext in MobileBankID"
                    if let error = QuickBalanceURL.checkCompletion(data: data, response: response, error: error, _where: _where) {
                        completion(nil, error)
                        return
                    }
                    
                    guard let data = data else {
                        let info = "Found nil when extracting data in " + _where
                        completion(nil, ApplicationError.unexpectedNil(info))
                        return
                    }
                    
                    print(data)
                    let newMobileBankIdResponse = MobileBankIDResponse(data: data)
                    print(newMobileBankIdResponse)
                    
                    guard !newMobileBankIdResponse.status.isEmpty else {
                        completion(nil, UserError.bankIdLoginFailed)
                        return
                    }
                    
                    completion(newMobileBankIdResponse, nil)
                }
                
            case .post:
                QuickBalanceURL.postRequest(apiRequest: links.uri, body: .init()) { data, response, error in
                    let _where = "goNext in MobileBankID"
                    if let error = QuickBalanceURL.checkCompletion(data: data, response: response, error: error, _where: _where) {
                        completion(nil, error)
                        return
                    }
                    
                    guard let data = data else {
                        let info = "Found nil when extracting data in " + _where
                        completion(nil, ApplicationError.unexpectedNil(info))
                        return
                    }
                    
                    let newMobileBankIdResponse = MobileBankIDResponse(data: data)
                    
                    guard !newMobileBankIdResponse.status.isEmpty else {
                        completion(nil, UserError.bankIdLoginFailed)
                        return
                    }
                    
                    completion(newMobileBankIdResponse, nil)
                }
                
            case .put:
                QuickBalanceURL.putRequest(apiRequest: links.uri) { data, response, error in
                    let _where = "goNext in MobileBankID"
                    if let error = QuickBalanceURL.checkCompletion(data: data, response: response, error: error, _where: _where) {
                        completion(nil, error)
                        return
                    }
                    
                    guard let data = data else {
                        let info = "Found nil when extracting data in " + _where
                        completion(nil, ApplicationError.unexpectedNil(info))
                        return
                    }
                    
                    let newMobileBankIdResponse = MobileBankIDResponse(data: data)
                    
                    guard !newMobileBankIdResponse.status.isEmpty else {
                        completion(nil, UserError.bankIdLoginFailed)
                        return
                    }
                    
                    completion(newMobileBankIdResponse, nil)
                }
            }
        }
    }
}
