//
//  OverheadsView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-19.
//

import SwiftUI

struct OverheadsView: View {
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel

    var body: some View {
        Form {
            let overheads = self.userViewModel.getOverheadsSorted()
            if overheads.count < 1 {
                Text("noOverheads")
            } else {
                Section {
                    HStack {
                        Text("sum")
                        Spacer()
                        Text("\(Utility.doubleToLocalCurrency(value:  self.userViewModel.user.budget.getOverheadsAmount()))")
                    }
                }
                
                Section {
                    ForEach(overheads) { overhead in
                        NavigationLink {
                            OverheadView(overhead: overhead)
                        } label: {
                            let myAmount = Utility.doubleToLocalCurrency(value: overhead.getMyAmount())
                            let amount = Utility.doubleToLocalCurrency(value: overhead.amount)
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(overhead.name)
                                        .bold()
                                    Text("\("day".localizeString()): \(overhead.dayOfPay)")
                                        .font(.footnote)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 5) {
                                    Text(myAmount)
                                        .bold()
                                    Text(amount)
                                        .font(.footnote)
                                }
                            }
                        }
                    }
                    .onDelete(perform: self.deleteOverheads)
                }
            }
        }
        .navigationTitle("overheads")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem {
                NavigationLink {
                    OverheadView(add: true)
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
    }

    private func deleteOverheads(offsets: IndexSet) {
        withAnimation {
            offsets.map { self.userViewModel.getOverheadsSorted()[$0] }.forEach { overhead in
                self.userViewModel.deleteOverhead(overhead: overhead) { error in
                    if let error = error {
                        self.errorHandling.handle(error: error)
                        return
                    }

                    // Success
                }
            }
        }
    }
}

struct OverheadsView_Previews: PreviewProvider {
    static var previews: some View {
        OverheadsView()
    }
}
