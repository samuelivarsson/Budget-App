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
    
    @State var categoryAmount: TransactionCategoryAmount
    @FocusState var isInputActive: Bool
    
    private var add: Bool

    init(add: Bool) {
        self.add = add
        self._categoryAmount = State(initialValue: TransactionCategoryAmount(categoryId: "", categoryName: "", amount: 0))
    }
    
    init(transactionCategoryAmount: TransactionCategoryAmount) {
        self.add = false
        self._categoryAmount = State(initialValue: transactionCategoryAmount)
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("transactionCategory")
                    
                    Spacer()
                    
                    Picker("", selection: self.$categoryAmount.categoryId) {
                        ForEach(self.userViewModel.user?.transactionCategories ?? []) { category in
                            let name = NSLocalizedString(category.name, comment: "")
                            Text(name).tag(category.id)
                        }
                    }
                }
                
                HStack {
                    Text("amount")
                        
                    Spacer()
                        
                    if self.categoryAmount.custom {
                        let user = self.userViewModel.getUser(errorHandling: self.errorHandling)
                        let amount: String = "\(self.categoryAmount.getCustomAmount(budget: user.budget)))"
                        Text(amount)
                    } else {
                        TextField(Utility.currencyFormatterNoSymbol.string(from: 0.0) ?? "0", value: self.$categoryAmount.amount, formatter: Utility.currencyFormatterNoSymbolNoZeroSymbol)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused(self.$isInputActive)
                            .padding(5)
                            .background(Color.tertiaryBackground)
                            .cornerRadius(8)
                            .fixedSize()
                    }
                        
                    Text(Utility.currencyFormatter.currencySymbol)
                }
                
                HStack {
                    Toggle("custom", isOn: self.$categoryAmount.custom)
                }
                
                if self.categoryAmount.custom {
                    HStack {
                        Text("percentageOfRemaining")
                        
                        Spacer()
                        
                        TextField(Utility.currencyFormatterNoSymbol.string(from: 0.0) ?? "0", value: self.$categoryAmount.amount, formatter: Utility.currencyFormatterNoSymbolNoZeroSymbol)
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
    }
    
    private func addTransactionCategoryAmount() {
        self.categoryAmount.categoryName = self.userViewModel.getTransactionCategory(id: self.categoryAmount.categoryId).name
        self.userViewModel.addTransactionCategoryAmount(newTGA: self.categoryAmount) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
            self.presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func editTransactionCategoryAmount() {
        self.userViewModel.editTransactionCategoryAmount(newTGA: self.categoryAmount) { error in
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
