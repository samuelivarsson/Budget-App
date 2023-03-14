//
//  TransactionCategoryAmountView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-04.
//

import SwiftUI

struct TransactionCategoryAmountView: View {
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var errorHandling: ErrorHandling
    
    @State var transactionCategoryAmount: TransactionCategoryAmount
    @FocusState var isInputActive: Bool
    
    private var add: Bool

    init(add: Bool) {
        self.add = add
        self._transactionCategoryAmount = State(initialValue: TransactionCategoryAmount(categoryId: "", categoryName: "", amount: 0))
    }
    
    init(transactionCategoryAmount: TransactionCategoryAmount) {
        self.add = false
        self._transactionCategoryAmount = State(initialValue: transactionCategoryAmount)
    }

    var body: some View {
        Form {
            Section {
                let user = self.userViewModel.user
                HStack {
                    Text("transactionCategory")
                    
                    Spacer()
                    
                    if self.add {
                        Picker("", selection: self.$transactionCategoryAmount.categoryId) {
                            ForEach(self.userViewModel.getTransactionCategoriesSorted(type: .expense)) { category in
                                let name = category.name.localizeString()
                                Text(name).tag(category.id)
                            }
                        }
                    } else {
                        let name = self.transactionCategoryAmount.categoryName.localizeString()
                        Text(name)
                    }
                }
                
                HStack {
                    Text("amount")
                        
                    Spacer()
                        
                    if self.transactionCategoryAmount.custom || user.budget.transactionCategoryThatUsesRest == self.transactionCategoryAmount.categoryId {
                        let amount: String = "\(self.transactionCategoryAmount.getRealAmount(budget: user.budget))"
                        Text(amount)
                    } else {
                        TextField(Utility.currencyFormatterNoSymbol.string(from: 0.0) ?? "0", value: self.$transactionCategoryAmount.amount, formatter: Utility.currencyFormatterNoSymbolNoZeroSymbol)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused(self.$isInputActive)
                            .padding(5)
                            .background(Color.tertiaryBackground)
                            .cornerRadius(8)
                            .fixedSize()
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                        
                                    Button("Done") {
                                        self.isInputActive = false
                                    }
                                }
                            }
                    }
                        
                    Text(Utility.currencyFormatter.currencySymbol)
                }
                 
                if user.budget.transactionCategoryThatUsesRest != self.transactionCategoryAmount.categoryId {
                    Toggle("custom", isOn: self.$transactionCategoryAmount.custom)
                    
                    if self.transactionCategoryAmount.custom {
                        HStack {
                            Text("percentageOfRemaining")
                            
                            Spacer()
                            
                            TextField(Utility.currencyFormatterNoSymbol.string(from: 0.0) ?? "0", value: self.$transactionCategoryAmount.customPercentage, formatter: Utility.currencyFormatterNoSymbolNoZeroSymbol)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused(self.$isInputActive)
                                .padding(5)
                                .background(Color.tertiaryBackground)
                                .cornerRadius(8)
                                .fixedSize()
                                .toolbar {
                                    ToolbarItemGroup(placement: .keyboard) {
                                        Spacer()
                                        
                                        Button("Done") {
                                            self.isInputActive = false
                                        }
                                    }
                                }
                            
                            Text("%")
                        }
                    }
                }
            } footer: {
                Text("transactionCategoryAmountNote")
            }
            
            Section {
                if self.add {
                    Button("add") {
                        self.addTransactionCategoryAmount()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Button("apply") {
                        self.editTransactionCategoryAmount()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("transactionCategoryAmount")
        .navigationBarTitleDisplayMode(.inline)
        .onLoad {
            let transactionCategories = self.userViewModel.getTransactionCategoriesSorted(type: .expense)
            if transactionCategories.count > 0 {
                self.transactionCategoryAmount.categoryId = transactionCategories[0].id
            }
        }
    }
    
    private func addTransactionCategoryAmount() {
        guard self.userViewModel.user.budget.transactionCategoryAmountsAreLowerThanRemaining(updated: self.transactionCategoryAmount) else {
            self.errorHandling.handle(error: InputError.transactionCategoryAmountsAddsUpToMoreThanRemaining)
            return
        }
        
        self.transactionCategoryAmount.categoryName = self.userViewModel.getTransactionCategory(id: self.transactionCategoryAmount.categoryId).name
        self.userViewModel.addTransactionCategoryAmount(newTGA: self.transactionCategoryAmount) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
            self.presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func editTransactionCategoryAmount() {
        guard self.userViewModel.user.budget.transactionCategoryAmountsAreLowerThanRemaining(updated: self.transactionCategoryAmount) else {
            self.errorHandling.handle(error: InputError.transactionCategoryAmountsAddsUpToMoreThanRemaining)
            return
        }
        
        self.userViewModel.editTransactionCategoryAmount(newTGA: self.transactionCategoryAmount) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
            self.presentationMode.wrappedValue.dismiss()
        }
    }
}

// struct TransactionCategoryAmountView_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionCategoryAmountView()
//    }
// }
