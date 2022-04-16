//
//  SettingsProvider.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-12.
//

import Foundation
import SwiftUI

//private let quickBalance: String = NSLocalizedString("quickbalance", comment: "")

final class SettingsProvider {
    private let settings: [Setting] = [
        Setting(name: "myInformation", imgName: "person", view: AnyView(MyInformationView())),
        Setting(name: "quickBalance", imgName: "creditcard", view: AnyView(QuickBalanceView()))
        
    ]
    
    func getSettings() -> [Setting] {
        return settings
    }
}

struct Setting: Identifiable {
    let id = UUID()

    let name: LocalizedStringKey
    let imgName: String
    let view: AnyView
}
