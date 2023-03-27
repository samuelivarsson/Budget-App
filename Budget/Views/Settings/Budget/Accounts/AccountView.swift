//
//  AccountView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-14.
//

import SwiftUI

struct AccountView: View {
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel
    
    @State private var account: Account
    @FocusState var isInputActive: Bool
    
    private var add: Bool
    
    init(add: Bool) {
        self.add = add
        self._account = State(initialValue: Account.getDummyAccount())
    }
    
    init(account: Account) {
        self.add = false
        self._account = State(initialValue: account)
    }
    
    var body: some View {
        Form {
            Section {
                Picker("", selection: self.$account.type) {
                    ForEach(AccountType.allCases, id: \.self) { type in
                        Text(type.description()).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                
                HStack {
                    Text("name")
                    Spacer()
                    TextField("", text: self.$account.name)
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
                
                HStack(spacing: 5) {
                    Text("amount")
                    TextField(Utility.currencyFormatterNoSymbol.string(from: 0.0) ?? "0", value: self.$account.baseAmount, formatter: Utility.currencyFormatterNoSymbolNoZeroSymbol)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .focused(self.$isInputActive)
                    Text(Utility.currencyFormatter.currencySymbol)
                }
                
                Toggle("mainAccount", isOn: self.$account.main)
            }
            
            Section {
                Button {
                    if self.add {
                        self.addAccount()
                    } else {
                        self.editAccount()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text(self.add ? "add" : "apply")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("budgetAccount")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func addAccount() {
        self.userViewModel.addBudgetAccount(account: self.account) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
            self.presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func editAccount() {
        self.userViewModel.editBudgetAccount(account: self.account) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
            self.presentationMode.wrappedValue.dismiss()
        }
    }
}

// struct AccountView_Previews: PreviewProvider {
//    static var previews: some View {
//        AccountView()
//    }
// }
