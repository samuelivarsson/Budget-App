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
    
    @State private var name: String = ""
    @State private var type: TransactionType = .expense
    @State private var useSavingsAccount: Bool = false
    @State private var useBuffer: Bool = false
    @FocusState var isInputActive: Bool
    
    private var add: Bool = false
    private var transactionCategory: TransactionCategory?
    
    init(add: Bool = false) {
        self.add = add
    }
    
    init(transactionCategory: TransactionCategory) {
        self.transactionCategory = transactionCategory
        self._name = State(initialValue: transactionCategory.name)
        self._type = State(initialValue: transactionCategory.type)
        self._useSavingsAccount = State(initialValue: transactionCategory.useSavingsAccount)
        self._useBuffer = State(initialValue: transactionCategory.useBuffer)
    }
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("name")
                    Spacer()
                    TextField("", text: self.$name).multilineTextAlignment(.trailing)
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
                HStack {
                    Text("type")
                    Spacer()
                    Picker("", selection: self.$type) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(type.description())
                        }
                    }
                }
                HStack {
                    Text("useSavingsAccount")
                    Spacer()
                    Toggle("", isOn: self.$useSavingsAccount)
                }
                HStack {
                    Text("useBuffer")
                    Spacer()
                    Toggle("", isOn: self.$useBuffer)
                }
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
    }
    
    private func addTransactionCategory() {
        let newTG = TransactionCategory(
            name: self.name,
            type: self.type,
            useSavingsAccount: self.useSavingsAccount,
            useBuffer: self.useBuffer
        )
        
        self.userViewModel.addTransactionCategory(newTG: newTG) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
            self.presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func editTransactionCategory() {
        guard let oldTG = self.transactionCategory else {
            let info = "Found nil when extracting transactionCategory in editTransactionCategory in TransactionCategoryView"
            self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
            return
        }
        
        let newTG = TransactionCategory(
            id: oldTG.id,
            name: self.name,
            type: self.type,
            useSavingsAccount: self.useSavingsAccount,
            useBuffer: self.useBuffer
        )
        
        self.userViewModel.editTransactionCategory(newTG: newTG) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
            self.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct TransactionCategoryView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionCategoryView()
    }
}
