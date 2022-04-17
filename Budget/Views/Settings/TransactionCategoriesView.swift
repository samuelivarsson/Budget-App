//
//  SetCategoriesView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-14.
//

import SwiftUI

struct TransactionCategoriesView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TransactionCategory.name, ascending: true)],
        animation: .default)
    private var transactionCategories: FetchedResults<TransactionCategory>
    
    var body: some View {
        Form {
            Text("hej")
        }
        .navigationTitle("transactionCategories")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TransactionCategoriesView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionCategoriesView()
    }
}
