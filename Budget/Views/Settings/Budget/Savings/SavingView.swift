//
//  SavingView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-19.
//

import SwiftUI

struct SavingView: View {
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var nextMonthChangesViewModel: NextMonthChangesViewModel

    @State private var savingAmount: Double
    @State private var changeNextMonth: Bool
    @FocusState var isInputActive: Bool
    
    private var accountId: String

    init(savingAmount: Double, accountId: String) {
        self._savingAmount = State(initialValue: savingAmount)
        self._changeNextMonth = State(initialValue: false)
        self.accountId = accountId
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("percentage")

                    Spacer()

                    TextField(Utility.currencyFormatterNoSymbol.string(from: 0.0) ?? "0", value: self.$savingAmount, formatter: Utility.currencyFormatterNoSymbolNoZeroSymbol)
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

                    Text(Utility.currencyFormatter.currencySymbol)
                }
            }
            
            Section {
                Toggle("changeNextMonth", isOn: self.$changeNextMonth)
                
                Button("apply") {
                    self.applySavingAmount()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("savingAmount")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func applySavingAmount() {
        if self.changeNextMonth {
            self.nextMonthChangesViewModel.addNextMonthChange(change: (self.accountId, self.savingAmount)) { error in
                if let error = error {
                    self.errorHandling.handle(error: error)
                    return
                }
                
                // Success
                self.presentationMode.wrappedValue.dismiss()
            }
            return
        }
        
        self.userViewModel.setSavingAmount(savingAmount: self.savingAmount, accountId: self.accountId) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
            }

            // Success
            self.presentationMode.wrappedValue.dismiss()
        }
    }
}

//struct SavingView_Previews: PreviewProvider {
//    static var previews: some View {
//        SavingView()
//    }
//}
