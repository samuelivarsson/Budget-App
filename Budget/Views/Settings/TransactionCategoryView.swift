//
//  TransactionCategoryView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-10-02.
//

import SwiftUI
import Firebase

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
                    Text("Name")
                    Spacer()
                    TextField("", text: $name).multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Type")
                    Spacer()
                    Picker("", selection: $type) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(type.description())
                        }
                    }
                }
                HStack {
                    Text("useSavingsAccount")
                    Spacer()
                    Toggle("", isOn: $useSavingsAccount)
                }
                HStack {
                    Text("useBuffer")
                    Spacer()
                    Toggle("", isOn: $useBuffer)
                }
            }
            
            Section {
                if add {
                    Button("add") {
                        addTransactionCategory()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Button("apply") {
                        editTransactionCategory()
                        presentationMode.wrappedValue.dismiss()
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
            print("hej")
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
        
        self.userViewModel.editTransactionCategory(oldTG: oldTG, newTG: newTG) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
        }
    }
}

struct TransactionCategoryView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionCategoryView()
    }
}
