//
//  BudgetWidgetBundle.swift
//  BudgetWidget
//
//  Created by Samuel Ivarsson on 2023-03-28.
//

import Firebase
import SwiftUI
import WidgetKit

@main
struct BudgetWidgetBundle: WidgetBundle {
    init() {
        FirebaseApp.configure()
        do {
            try Auth.auth().useUserAccessGroup("\(Utility.teamId).com.samuelivarsson.Budget")
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }

    var body: some Widget {
        BudgetWidget()
    }
}
