//
//  ProfileListResponse.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-25.
//

import Foundation

struct ProfileListResponse: Codable {
    var bank: Bank
    
    init(data: [String: Any]) {
        self.bank = Bank(data: (data["banks"] as? [[String: Any]] ?? .init()).first ?? .init())
    }
    
    struct Bank: Codable {
        var privateProfile: Profile
        
        init(data: [String: Any]) {
            self.privateProfile = Profile(data: data["privateProfile"] as? [String: Any] ?? .init())
        }
        
        struct Profile: Codable {
            var id: String
            
            init(data: [String: Any]) {
                self.id = data["id"] as? String ?? ""
            }
        }
    }
}
