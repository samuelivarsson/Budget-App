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

    @State private var savingAmount: Double
    @FocusState var isInputActive: Bool
    
    private var accountId: String

    init(savingAmount: Double, accountId: String) {
        self._savingAmount = State(initialValue: savingAmount)
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
