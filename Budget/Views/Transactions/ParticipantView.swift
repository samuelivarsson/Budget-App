//
//  ParticipantView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2024-03-03.
//

import SwiftUI
import MathParser

struct ParticipantView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var errorHandling: ErrorHandling
    
    @Binding var participant: Participant
    @Binding var splitOption: SplitOption
    @Binding var participants: [Participant]
    @Binding var totalAmount: Double
    
    @State var amountString: String = ""
    @State var amountSelected: Bool = false
    @Binding var hasWritten: [String]
    
    @FocusState var isInputActive: Bool
    
    var action: TransactionAction
    
    var body: some View {
        HStack {
            Text(participant.userId == userViewModel.user.id ? "you".localizeString() : participant.userName)
            Spacer()
            if splitOption == SplitOption.meEverything || splitOption == SplitOption.heSheEverything || action == .view {
                Text(Utility.doubleToLocalCurrency(value: participant.amount))
                    .padding(5)
            } else {
                HStack {
                    TextField(Utility.currencyFormatterNoSymbol.string(from: 0.0) ?? "0", text: self.$amountString, onEditingChanged: { isEditing in
                        self.amountSelected = isEditing
                        if !isEditing {
                            let expression = self.amountString
                                .replacingOccurrences(of: ",", with: ".")
                                .replacingOccurrences(of: "÷", with: "/")
                                .replacingOccurrences(of: "×", with: "*")
                            if let doubleAmount = try? expression.evaluate() {
                                DispatchQueue.main.async {
                                    self.participant.amount = Utility.doubleToTwoDecimals(value: doubleAmount)
                                    
                                    if let errorString = Utility.setAmountPerParticipant(splitOption: self.splitOption, participants: self.$participants, totalAmount: self.totalAmount, hasWritten: self.hasWritten, myUserId: self.userViewModel.user.id) {
                                        self.errorHandling.handle(error: ApplicationError.unexpectedNil(errorString))
                                    }
                                }
                            }
                        }
                    })
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .focused(self.$isInputActive)
                    .padding(5)
                    .background(Color.tertiaryBackground)
                    .cornerRadius(8)
                    .fixedSize()
                    .toolbar {
                        if self.amountSelected {
                            ToolbarItemGroup(placement: .keyboard) {
                                CalculatorToolbarView(amountString: self.$amountString)
                                    
                                Spacer()
                                    
                                Button("Done") {
                                    self.isInputActive = false
                                }
                            }
                        }
                    }
                    Text(Utility.currencyFormatter.currencySymbol)
                }
            }
        }
        .deleteDisabled(self.participant.userId == userViewModel.user.id || action == .view)
        .onChange(of: self.amountString) { _ in
            DispatchQueue.main.async {
                if self.amountSelected && !self.hasWritten.contains(self.participant.userId) {
                    self.hasWritten.append(self.participant.userId)
                }
            }
        }
        .onChange(of: self.participant.amount) { newValue in
            DispatchQueue.main.async {
                self.amountString = Utility.currencyFormatterNoSymbolNoZeroSymbol.string(from: newValue as NSNumber) ?? "-999"
            }
        }
        .onLoad {
            self.amountString = Utility.currencyFormatterNoSymbolNoZeroSymbol.string(from: participant.amount as NSNumber) ?? "-999"
        }
    }
}

// #Preview {
//    ParticipantView()
// }
