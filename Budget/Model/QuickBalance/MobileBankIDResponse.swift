//
//  MobileBankIDResponse.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-25.
//

import Foundation

struct MobileBankIDResponse: Codable {
    let status: String
    let autoStartToken: String
    let links: MobileBankIDResponseLinks
    
    init(status: String, autoStartToken: String, links: MobileBankIDResponseLinks) {
        self.status = status
        self.autoStartToken = autoStartToken
        self.links = links
    }
    
    init(data: [String: Any]) {
        self.status = data["status"] as? String ?? ""
        self.autoStartToken = data["autoStartToken"] as? String ?? ""
        self.links = MobileBankIDResponseLinks(data: data["links"] as? [String: Any] ?? .init())
    }
    
    static func getDummyResponse() -> MobileBankIDResponse {
        return MobileBankIDResponse(status: "", autoStartToken: "", links: MobileBankIDResponseLinks.getDummyResponseLinks())
    }
}

struct MobileBankIDResponseLinks: Codable {
    var method: String
    var uri: String
    
    init(method: String, uri: String) {
        self.method = method
        self.uri = uri
    }
    
    init(data: [String: Any]) {
        let nextData = data["next"] as? [String: Any] ?? .init()
        self.method = nextData["method"] as? String ?? ""
        self.uri = nextData["uri"] as? String ?? ""
    }
    
    static func getDummyResponseLinks() -> MobileBankIDResponseLinks {
        return MobileBankIDResponseLinks(method: "", uri: "")
    }
    
    func getHTTPMethod() -> HTTPMethod {
        if self.method == "POST" {
            return .post
        } else if self.method == "PUT" {
            return .put
        }
        return .get
    }
}
