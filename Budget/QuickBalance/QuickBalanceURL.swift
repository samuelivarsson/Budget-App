//
//  QuickBalanceURL.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-25.
//

import Foundation

struct QuickBalanceURL {
    private static var _baseUri = "https://auth.api.swedbank.se/TDE_DAP_Portal_REST_WEB/api/"
    private static var _appId: String = "2yQYNFI11KK4eJOP"
    private static var _userAgent: String = "SamuelIvarssonWidgetApp"
    
    static func genAuthorizationKey(appId: String) -> String {
        let string = appId + ":" + UUID().uuidString
        let data = string.data(using: String.Encoding.utf8)
        guard let output: String = data?.base64EncodedString() else {
            print("Error for some reason while generating auth key")
            return ""
        }
        return output
    }
    
    static func dsidGen() -> String {
        var dsid = String(Int.random(in: 1...999999)).sha1()
        dsid = String(dsid.suffix(dsid.count - Int.random(in: 1...30)))
        dsid = String(dsid.prefix(8))
        dsid = String(dsid.prefix(4) + dsid.suffix(4).uppercased())
        
        return String(dsid.shuffled())
    }
    
    static func getRequest(apiRequest: String, completion: @escaping ([String: Any]?, HTTPURLResponse?, Error?) -> Void) {
        let request = createRequest(method: "get", apiRequest: apiRequest)
        sendRequest(request: request, completion: completion)
    }
    
    static func postRequest(apiRequest: String, body: [String: Any], completion: @escaping ([String: Any]?, HTTPURLResponse?, Error?) -> Void) {
        var headers: [String: String] = [:]
        if body.count > 0 {
            headers["Content-Type"] = "application/json; charset=UTF-8"
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: body, options: [])
            let request = createRequest(method: "post", apiRequest: apiRequest, headers: headers, data: data)
            return sendRequest(request: request, completion: completion)
        } catch {
            let info = "JSONSerialization failed in postRequest in MobileBankID"
            completion(nil, nil, ApplicationError.unexpectedNil(info))
        }
    }
    
    static func putRequest(apiRequest: String, completion: @escaping ([String: Any]?, HTTPURLResponse?, Error?) -> Void) {
        let request = createRequest(method: "put", apiRequest: apiRequest)
        sendRequest(request: request, completion: completion)
    }
    
    static func createRequest(method: String, apiRequest: String, headers: [String: String] = [:], data: Data = Data()) -> URLRequest {
        let dsid = dsidGen()
        let dsidString = "dsid=\(dsid)"
        
        let url = URL(string: _baseUri + apiRequest + "?" + dsidString)
        guard let requestUrl = url else {
            fatalError()
        }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = method.uppercased()
        
        request.setValue(genAuthorizationKey(appId: _appId), forHTTPHeaderField: "Authorization")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("sv-se", forHTTPHeaderField: "Accept-Language")
        request.setValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.setValue(_userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("isMobile:true", forHTTPHeaderField: "ADRUM_1")
        
        let cookieProps: [HTTPCookiePropertyKey: Any] = [
            HTTPCookiePropertyKey.domain: ".api.swedbank.se",
            HTTPCookiePropertyKey.path: "/",
            HTTPCookiePropertyKey.name: "dsid",
            HTTPCookiePropertyKey.value: dsid
        ]
        
        if let cookie = HTTPCookie(properties: cookieProps) {
            HTTPCookieStorage.shared.setCookie(cookie)
        }
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if !data.isEmpty {
            request.httpBody = data
        }
        
        return request
    }
    
    static func sendRequest(request: URLRequest, completion: @escaping ([String: Any]?, HTTPURLResponse?, Error?) -> Void) {
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Check if Error took place
            if let error = error {
                completion(nil, nil, error)
                return
            }
            
            // Read HTTP Response Status code
            guard let response = response as? HTTPURLResponse else {
                let info = "Found nil when extracting response in sendRequest in MobileBankID"
                completion(nil, nil, ApplicationError.unexpectedNil(info))
                return
            }
            
            // Convert HTTP Response Data to a simple String
            guard let data = data else {
                let info = "Found nil when extracting data in sendRequest in MobileBankID"
                completion(nil, nil, ApplicationError.unexpectedNil(info))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                completion(json, response, nil)
            } catch {
                if response.statusCode < 200 || response.statusCode >= 300 {
                    completion([:], response, nil)
                    return
                }
                completion([:], response, nil)
            }
            
        }.resume()
    }
    
    static func checkCompletion(data: [String: Any]?, response: HTTPURLResponse?, error: Error?, _where: String) -> Error? {
        if let error = error {
            return error
        }
        
        guard let response = response else {
            let info = "Found nil when extracting response in " + _where
            return ApplicationError.unexpectedNil(info)
        }
        
        guard let data = data else {
            let info = "Found nil when extracting data in " + _where
            return ApplicationError.unexpectedNil(info)
        }
        
        guard response.statusCode >= 200, response.statusCode < 300 else {
            let quickBalanceErrorResponse = QuickBalanceErrorResponse(data: data)
            return HTTPError.badQuickBalanceCode(quickBalanceErrorResponse, response)
        }
        
        return nil
    }
}
