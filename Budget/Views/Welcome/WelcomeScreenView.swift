//
//  WelcomeScreenView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-14.
//

import SwiftUI

struct WelcomeScreenView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var errorHandling: ErrorHandling
    @AppStorage("welcomeScreenShown") private var welcomeScreenShown: Bool = false
    
    var body: some View {
        NavigationView {
            TabView {
                LoginView()
                TransactionCategoriesView()
            }
            .navigationTitle("welcome")
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .toolbar {
                ToolbarItem {
                    Button {
                        welcomeScreenShown = true
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .onAppear {
                addCategories()
            }
        }
    }
    
    private func addCategories() {
        let food = TransactionCategory(context: viewContext)
        food.id = UUID()
        food.name = NSLocalizedString("food", comment: "food")
        food.type = .expense
        
        let fika = TransactionCategory(context: viewContext)
        fika.id = UUID()
        fika.name = NSLocalizedString("fika", comment: "fika")
        fika.type = .expense
        
        let transportation = TransactionCategory(context: viewContext)
        transportation.id = UUID()
        transportation.name = NSLocalizedString("transportation", comment: "transportation")
        transportation.type = .expense
        
        let other = TransactionCategory(context: viewContext)
        other.id = UUID()
        other.name = NSLocalizedString("other", comment: "other")
        other.type = .expense
        
        let savingsAccountPurchase = TransactionCategory(context: viewContext)
        savingsAccountPurchase.id = UUID()
        savingsAccountPurchase.name = NSLocalizedString("savingsAccountPurchase", comment: "savingsAccountPurchase")
        savingsAccountPurchase.type = .expense
        savingsAccountPurchase.useSavingsAccount = true
        
        let groceries = TransactionCategory(context: viewContext)
        groceries.id = UUID()
        groceries.name = NSLocalizedString("groceries", comment: "groceries")
        groceries.type = .expense
        
        let extraSaving = TransactionCategory(context: viewContext)
        extraSaving.id = UUID()
        extraSaving.name = NSLocalizedString("extraSaving", comment: "extraSaving")
        extraSaving.type = .saving

        let savingsAccount = TransactionCategory(context: viewContext)
        savingsAccount.id = UUID()
        savingsAccount.name = NSLocalizedString("savingsAccount", comment: "savingsAccount")
        savingsAccount.type = .income
        savingsAccount.useSavingsAccount = true
        
        let swish = TransactionCategory(context: viewContext)
        swish.id = UUID()
        swish.name = NSLocalizedString("swish", comment: "swish")
        swish.type = .income
        
        let buffer = TransactionCategory(context: viewContext)
        buffer.id = UUID()
        buffer.name = NSLocalizedString("buffer", comment: "buffer")
        buffer.type = .income
        buffer.useBuffer = true
        
        do {
            try viewContext.save()
        } catch {
            errorHandling.handle(error: error)
        }
    }
}

struct WelcomeScreenView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeScreenView()
    }
}
