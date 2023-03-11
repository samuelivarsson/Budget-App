//
//  IncomeView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-11.
//

import SwiftUI

struct IncomeView: View {
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel

    @State private var income: Double
    @FocusState var isInputActive: Bool

    init(income: Double) {
        self._income = State(initialValue: income)
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("amount")

                    Spacer()

                    TextField(Utility.currencyFormatterNoSymbol.string(from: 0.0) ?? "0", value: self.$income, formatter: Utility.currencyFormatterNoSymbolNoZeroSymbol)
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
                    self.applyIncome()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("income")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func applyIncome() {
        self.userViewModel.setIncome(income: self.income) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
            }

            // Success
            self.presentationMode.wrappedValue.dismiss()
        }
    }
}

// struct IncomeView_Previews: PreviewProvider {
//    static var previews: some View {
//        IncomeView()
//    }
// }
