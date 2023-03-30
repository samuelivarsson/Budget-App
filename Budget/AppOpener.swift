//
//  AppOpener.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-31.
//

import Foundation
import SwiftUI

struct AppOpener {
    static func openBankId(autoStartToken: String, completion: @escaping (Error?) -> Void) {
        DispatchQueue.main.async {
            if let url = URL(string: "https://app.bankid.com/?autostarttoken=\(autoStartToken)&redirect=budgetapp://?sourceApplication=bankid") {
                UIApplication.shared.open(url) { success in
                    guard success else {
                        completion(UserError.bankIdNotInstalled)
                        return
                    }
                }
            }
        }
    }

    static func openSwish(amount: Double, friend: User) {
        if let url = Utility.getSwishUrl(amount: amount, friend: friend) {
            UIApplication.shared.open(url)
        }
    }
}
