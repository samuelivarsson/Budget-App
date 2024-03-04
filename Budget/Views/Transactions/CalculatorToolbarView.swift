//
//  CalculatorToolbarView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2024-03-03.
//

import SwiftUI

struct CalculatorToolbarView: View {
    @Binding var amountString: String
    
    var body: some View {
        HStack(spacing: 10) {
            Button("+") {
                self.amountString += "+"
            }
            Button("-") {
                self.amountString += "-"
            }
            Button("÷") {
                self.amountString += "÷"
            }
            Button("×") {
                self.amountString += "×"
            }
            Button("(") {
                self.amountString += "("
            }
            Button(")") {
                self.amountString += ")"
            }
        }
    }
}
