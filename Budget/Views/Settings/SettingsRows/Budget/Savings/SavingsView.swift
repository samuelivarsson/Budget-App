//
//  SavingsView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-19.
//

import SwiftUI

struct SavingsView: View {
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel

    @State private var savingsPercentage: Double
    @FocusState var isInputActive: Bool

    init(savingsPercentage: Double) {
        self._savingsPercentage = State(initialValue: savingsPercentage)
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("percentage")

                    Spacer()

                    TextField(Utility.currencyFormatterNoSymbol.string(from: 0.0) ?? "0", value: self.$savingsPercentage, formatter: Utility.currencyFormatterNoSymbolNoZeroSymbol)
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

            Section {
                Button("apply") {
                    self.applySavingsPercentage()
                }
                .frame(maxWidth: .infinity)
            }

            Section {
                let sum = self.userViewModel.user.budget.getSavings()
                HStack {
                    Text("sum")
                    Spacer()
                    Text(Utility.doubleToLocalCurrency(value: sum))
                }

                ForEach(self.userViewModel.getAccounts(type: .saving)) { account in
                    let savingAmount = self.userViewModel.getSavingAmount(accountId: account.id)
                    if account.main {
                        Text("\(account.name): \(Utility.doubleToLocalCurrency(value: savingAmount))")
                    } else {
                        NavigationLink {
                            SavingView(savingAmount: savingAmount, accountId: account.id)
                        } label: {
                            Text("\(account.name): \(Utility.doubleToLocalCurrency(value: savingAmount))")
                        }
                    }
                }
            } header: {
                Text("savingAccounts")
            }
        }
        .navigationTitle("savingsPercentage")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func applySavingsPercentage() {
        self.userViewModel.setSavingsPercentage(savingsPercentage: self.savingsPercentage) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
            }

            // Success
        }
    }
}

// struct SavingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SavingsView()
//    }
// }
