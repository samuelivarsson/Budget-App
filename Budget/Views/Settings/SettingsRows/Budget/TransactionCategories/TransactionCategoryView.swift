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
                
                self.takesFrom
                
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
        .navigationTitle("transactionCategory")
        .navigationBarTitleDisplayMode(.inline)
        .onLoad {
            guard self.userViewModel.getAccounts().count > 0 else {
                self.errorHandling.handle(error: UserError.noAccountsYet)
                self.presentationMode.wrappedValue.dismiss()
                return
            }
        }
    }
    
    private var takesFrom: some View {
        Picker("takesFrom", selection: self.$transactionCategory.takesFromAccount) {
            if self.transactionCategory.type != .expense {
                Text("none").tag("")
            }
            ForEach(self.userViewModel.getAccounts()) { account in
                Text(account.name).tag(account.id)
            }
        }
        .onLoad {
            self.setFirstTakesFromAccount()
        }
        .onChange(of: self.transactionCategory.type) { _ in
            self.setFirstTakesFromAccount()
        }
    }
    
    private var givesTo: some View {
        Picker("givesTo", selection: self.$transactionCategory.givesToAccount) {
            Text("none").tag("")
            ForEach(self.userViewModel.getAccounts()) { account in
                Text(account.name).tag(account.id)
            }
        }
        .onLoad {
            self.setFirstGivesToAccount()
        }
        .onChange(of: self.transactionCategory.type) { _ in
            self.setFirstGivesToAccount()
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
    
    private func setFirstTakesFromAccount() {
        if self.add {
            guard let first = self.userViewModel.getAccounts().first else {
                self.errorHandling.handle(error: UserError.noAccountsYet)
                return
            }
            
            self.transactionCategory.takesFromAccount = first.id
        }
    }
    
    private func setFirstGivesToAccount() {
        if self.add {
            guard let first = self.userViewModel.getAccounts().first else {
                self.errorHandling.handle(error: UserError.noAccountsYet)
                return
            }
            
            self.transactionCategory.givesToAccount = first.id
        }
    }
}

struct TransactionCategoryView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionCategoryView()
    }
}
