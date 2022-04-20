//
//  TransactionView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-14.
//

import SwiftUI
import Combine
import CoreData

struct TransactionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)],
                animation: .default)
    private var transactionCategories: FetchedResults<TransactionCategory>
    
    @State private var type: TransactionType = .expense
    @State private var category: String = ""
    @State private var descriptionText = ""
    @State private var amountText = ""
    @State private var date = Date()
    
    var add: Bool
    
    init(add: Bool = false) {
        self.add = add
    }
    
    init(transaction: Transaction) {
        self.add = false
        self._type = State(initialValue: transaction.type)
        self._category = State(initialValue: transaction.category ?? "")
        self._descriptionText = State(initialValue: transaction.desc ?? "")
        self._amountText = State(initialValue: String(transaction.amount))
        self._date = State(initialValue: transaction.date!)
    }
    
    var body: some View {
        Form {
            Section {
                typeView
                categoryView
                descriptionView
                amountView
                datePicker
            }
            
            Section(add ? "addParticipants" : "editParticipants") {
                // TODO - Create functionality to add participants
                Text("Hej")
            }
            
            Section {
                Button(add ? "add" : "apply") {
                    // TODO - Edit transaction instead of creating new
                    addTransaction()
                    presentationMode.wrappedValue.dismiss()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle(add ? "addTransaction" : "editTransaction")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var typeView: some View {
        Picker("type", selection: $type) {
            ForEach(TransactionType.allCases, id: \.self) { type in
                Text(type.description())
            }
        }
        .pickerStyle(.segmented)
    }
    
    private var categoryView: some View {
        HStack(spacing: 30) {
            Text("category")
            Spacer().frame(maxWidth: .infinity)
            let list = transactionCategories.filter {$0.type == type}
            switch type {
            case .expense:
                CategoryPicker(list: list, category: $category)
            case .income:
                CategoryPicker(list: list, category: $category)
            case .saving:
                CategoryPicker(list: list, category: $category)
            }
            
        }
    }
    
    private struct CategoryPicker: View {
        var list: [TransactionCategory]
        @Binding var category: String
        
        var body: some View {
            Picker("category", selection: $category) {
                ForEach(list) { category in
                    Text(LocalizedStringKey(category.name!)).tag(category.name!)
                }
            }
            .pickerStyle(.menu)
            .onAppear {
                guard let first = list.first else {
                    print("There are no categories!")
                    return
                }
                guard let name = first.name else {
                    print("Failed to get the name of the category!")
                    return
                }
                category = name
            }
        }
    }
    
    private var descriptionView: some View {
        HStack(spacing: 30) {
            Text("description")
            TextField("description", text: $descriptionText, prompt: Text("shortDescription"))
                .multilineTextAlignment(.trailing)
        }
    }
    
    private var amountView: some View {
        HStack(spacing: 30) {
            Text("amount")
            TextField("0", text: $amountText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .onReceive(Just(amountText)) { newValue in
                    // Only allow numbers and decimal separators
                    let filtered = newValue.filter { "0123456789,.".contains($0) }
                    if filtered != newValue {
                        self.amountText = filtered
                        return
                    }
                    
                    // Only allow one decimal separator
                    let decimalSeparatorCount = newValue.filter { ",.".contains($0) }.count
                    if decimalSeparatorCount > 1 {
                        self.amountText = String(newValue.dropLast())
                        return
                    }
                    
                    // Only allow 2 decimals
                    let replaced = newValue.replacingOccurrences(of: ",", with: ".")
                    if let separatorIndex = replaced.firstIndex(of: ".") {
                        if replaced[separatorIndex...].count > 3 {
                            self.amountText = String(newValue.dropLast())
                        }
                    }
                }
        }
    }
    
    private var datePicker: some View {
        DatePicker("date", selection: $date)
            .onAppear {
                if add {
                    date = Date()
                }
            }
    }
    
    private func addTransaction() {
        withAnimation {
            let newTransaction = Transaction(context: viewContext)
            newTransaction.id = UUID()
            newTransaction.type = type
            newTransaction.category = category
            newTransaction.desc = descriptionText
            let amount = amountText.replacingOccurrences(of: ",", with: ".")
            newTransaction.amount = Double(amount) ?? 0
            newTransaction.date = date
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct TransactionView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionView()
            .environmentObject(AuthViewModel())
    }
}
