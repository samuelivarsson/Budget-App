//
//  BudgetWidgetBundle.swift
//  BudgetWidget
//
//  Created by Samuel Ivarsson on 2023-03-28.
//

import WidgetKit
import SwiftUI

@main
struct BudgetWidgetBundle: WidgetBundle {
    var body: some Widget {
        BudgetWidget()
        BudgetWidgetLiveActivity()
    }
}
