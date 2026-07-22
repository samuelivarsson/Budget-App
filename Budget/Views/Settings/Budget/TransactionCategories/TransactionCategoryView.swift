//
//  TransactionCategoryView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-10-02.
//

import Firebase
import SwiftUI

struct TransactionCategoryView: View {
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var fireStoreViewModel: FirestoreViewModel
    
    @State private var transactionCategory: TransactionCategory
    @State private var useRest: Bool = false
    @FocusState var isInputActive: Bool
    
    private var add: Bool = false
    
    init(add: Bool = false) {
        self.add = add
        self._transactionCategory = State(initialValue: TransactionCategory.getDummyCategory())
    }
    
    init(transactionCategory: TransactionCategory) {
        self._transactionCategory = State(initialValue: transactionCategory)
    }
    
    var body: some View {
        Form {
            Section {
                Picker("type", selection: self.$transactionCategory.type) {
                    ForEach(TransactionType.allCases, id: \.self) { type in
                        Text(type.description()).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                    
                HStack {
                    Text("name")
                    Spacer()
                    TextField("", text: self.$transactionCategory.name)
                        .multilineTextAlignment(.trailing)
                        .focused(self.$isInputActive)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                    
                                Button("Done") {
                                    self.isInputActive = false
                                }
                            }
                        }
                }
                
                // income = gives only, expense = takes only, transfer = both.
                if self.transactionCategory.type != .income {
                    self.takesFrom
                }
                if self.transactionCategory.type != .expense {
                    self.givesTo
                }
            } header: {
                Text("details")
            }
                
            Section {
                Toggle("categoryCeiling", isOn: self.$transactionCategory.ceiling)
                
                if self.transactionCategory.ceiling {
                    if self.add {
                        Toggle("useRest", isOn: self.$useRest)
                    }
                    
                    let user = self.userViewModel.user
                    HStack {
                        Text("amount")
                            
                        Spacer()
                            
                        if self.transactionCategory.customCeiling || user.budget.transactionCategoryThatUsesRest == self.transactionCategory.id || self.useRest {
                            Text(Utility.doubleToLocalCurrency(value: self.transactionCategory.getRealAmount(budget: user.budget, useRest: self.useRest)))
                        } else {
                            TextField(Utility.currencyFormatterNoSymbol.string(from: 0.0) ?? "0", value: self.$transactionCategory.ceilingAmount, formatter: Utility.currencyFormatterNoSymbolNoZeroSymbol)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused(self.$isInputActive)
                                .padding(5)
                                .background(Color.tertiaryBackground)
                                .cornerRadius(8)
                                .fixedSize()
                                
                            Text(Utility.currencyFormatter.currencySymbol)
                        }
                    }
                        
                    if user.budget.transactionCategoryThatUsesRest != self.transactionCategory.id && !self.useRest {
                        Toggle("custom", isOn: self.$transactionCategory.customCeiling)
                            
                        if self.transactionCategory.customCeiling {
                            HStack {
                                Text("percentageOfRemaining")
                                    
                                Spacer()
                                    
                                TextField(Utility.currencyFormatterNoSymbol.string(from: 0.0) ?? "0", value: self.$transactionCategory.customCeilingPercentage, formatter: Utility.currencyFormatterNoSymbolNoZeroSymbol)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .focused(self.$isInputActive)
                                    .padding(5)
                                    .background(Color.tertiaryBackground)
                                    .cornerRadius(8)
                                    .fixedSize()
                                    
                                Text("%")
                            }
                        }
                    }
                }
            } header: {
                Text("ceiling")
            }
                
            Section {
                if self.add {
                    Button("add") {
                        self.addTransactionCategory()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Button("apply") {
                        self.editTransactionCategory()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .iosFormBackground()
        .navigationTitle("transactionCategory")
        .navigationBarTitleDisplayMode(.inline)
        .onLoad {
            guard self.userViewModel.getAccounts().count > 0 else {
                self.errorHandling.handle(error: UserError.noAccountsYet)
                self.presentationMode.wrappedValue.dismiss()
                return
            }
            // Reflect the true structure so a legacy mislabeled category (e.g. an
            // income that also draws from an account) opens as its effective type.
            if !self.add {
                self.transactionCategory.type = self.transactionCategory.moneyFlow
            }
            self.normalizeAccounts()
        }
        .onChange(of: self.transactionCategory.type) { _ in
            self.normalizeAccounts()
        }
    }
    
    private var takesFrom: some View {
        Picker("takesFrom", selection: self.$transactionCategory.takesFromAccount) {
            ForEach(self.userViewModel.getAccounts()) { account in
                Text(account.name).tag(account.id)
            }
        }
    }

    private var givesTo: some View {
        Picker("givesTo", selection: self.$transactionCategory.givesToAccount) {
            ForEach(self.userViewModel.getAccounts()) { account in
                Text(account.name).tag(account.id)
            }
        }
    }
    
    private func addTransactionCategory() {
        guard self.userViewModel.user.budget.transactionCategoriesAreLowerThanRemaining(updated: self.transactionCategory) else {
            self.errorHandling.handle(error: InputError.transactionCategoryAmountsAddsUpToMoreThanRemaining)
            return
        }
        
        self.userViewModel.addTransactionCategory(newTG: self.transactionCategory, useRest: self.useRest) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
            self.presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func editTransactionCategory() {
        guard self.userViewModel.user.budget.transactionCategoriesAreLowerThanRemaining(updated: self.transactionCategory) else {
            self.errorHandling.handle(error: InputError.transactionCategoryAmountsAddsUpToMoreThanRemaining)
            return
        }
        
        self.userViewModel.editTransactionCategory(newTG: self.transactionCategory) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
            self.presentationMode.wrappedValue.dismiss()
        }
    }
    
    /// Keeps the account fields consistent with the selected type:
    /// income clears takesFrom, expense clears givesTo, transfer needs both.
    /// Visible-but-empty fields default to the first account.
    private func normalizeAccounts() {
        guard let first = self.userViewModel.getAccounts().first else {
            self.errorHandling.handle(error: UserError.noAccountsYet)
            return
        }
        switch self.transactionCategory.type {
        case .income:
            self.transactionCategory.takesFromAccount = ""
            if self.transactionCategory.givesToAccount.isEmpty { self.transactionCategory.givesToAccount = first.id }
        case .expense:
            self.transactionCategory.givesToAccount = ""
            if self.transactionCategory.takesFromAccount.isEmpty { self.transactionCategory.takesFromAccount = first.id }
        case .transfer:
            if self.transactionCategory.takesFromAccount.isEmpty { self.transactionCategory.takesFromAccount = first.id }
            if self.transactionCategory.givesToAccount.isEmpty { self.transactionCategory.givesToAccount = first.id }
        }
    }
}

struct TransactionCategoryView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionCategoryView()
    }
}
