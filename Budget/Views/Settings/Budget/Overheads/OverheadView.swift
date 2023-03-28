//
//  OverheadView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-19.
//

import SwiftUI

struct OverheadView: View {
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel
    
    @State private var overhead: Overhead
    @State private var day: Int
    @State private var receiveDay: Int
    @FocusState var isInputActive: Bool
    
    private var add: Bool
    
    init(add: Bool) {
        self.add = add
        let overhead = Overhead.getDummyOverhead()
        self._overhead = State(initialValue: overhead)
        self._day = State(initialValue: overhead.dayOfPay - 1)
        self._receiveDay = State(initialValue: overhead.receiveDay - 1)
    }
    
    init(overhead: Overhead) {
        self.add = false
        self._overhead = State(initialValue: overhead)
        self._day = State(initialValue: overhead.dayOfPay - 1)
        self._receiveDay = State(initialValue: overhead.receiveDay - 1)
    }
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("name")
                    Spacer()
                    TextField("", text: self.$overhead.name)
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
                    TextField(Utility.currencyFormatterNoSymbol.string(from: 0.0) ?? "0", value: self.$overhead.amount, formatter: Utility.currencyFormatterNoSymbolNoZeroSymbol)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .focused(self.$isInputActive)
                    Text(Utility.currencyFormatter.currencySymbol)
                }
                
                Picker("dayOfPay", selection: self.$day) {
                    ForEach(1 ..< 29) {
                        Text("\($0)")
                    }
                }
                .pickerStyle(.menu)
                .disabled(self.overhead.lastDay)
                
                Stepper(value: self.$overhead.months, in: 1 ... 6) {
                    HStack {
                        Text("months")
                        Spacer()
                        Text("\(self.overhead.months)")
                            .padding(.trailing, 5)
                    }
                }
                
                if self.overhead.months > 1 {
                    DatePicker("startDate", selection: self.$overhead.startDate)
                        .onLoad {
                            if self.add {
                                self.overhead.startDate = Date()
                            }
                        }
                }
                
                Toggle("share", isOn: self.$overhead.share)
                
                if self.overhead.share {
                    Toggle("imPaying", isOn: self.$overhead.imPaying)
                    
                    if self.overhead.imPaying {
                        Picker("receiveDay", selection: self.$receiveDay) {
                            ForEach(1 ..< 29) {
                                Text("\($0)")
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            } footer: {
                Text("overheadNote")
            }
            
            Section {
                Button {
                    if self.add {
                        self.addOverhead()
                    } else {
                        self.editOverhead()
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
        .navigationTitle("overhead")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func addOverhead() {
        self.overhead.dayOfPay = self.day + 1
        self.overhead.receiveDay = self.receiveDay + 1
        self.userViewModel.addOverhead(overhead: self.overhead) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
            self.presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func editOverhead() {
        self.overhead.dayOfPay = self.day + 1
        self.overhead.receiveDay = self.receiveDay + 1
        self.userViewModel.editOverhead(overhead: self.overhead) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
            self.presentationMode.wrappedValue.dismiss()
        }
    }
}

// struct OverheadView_Previews: PreviewProvider {
//    static var previews: some View {
//        OverheadView()
//    }
// }
