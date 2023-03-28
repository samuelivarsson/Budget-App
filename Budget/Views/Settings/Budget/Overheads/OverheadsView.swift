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
                            let monthStartsOn = self.userViewModel.user.budget.monthStartsOn
                            let myShare = overhead.getShareOfAmount(monthStartsOn: monthStartsOn)
                            let balanceOnAccount = overhead.getTemporaryBalanceOnAccount(monthStartsOn: monthStartsOn)
                            VStack(spacing: 5) {
                                HStack {
                                    Text(overhead.name)
                                        .bold()
                                Spacer()
                                    Text(Utility.doubleToLocalCurrency(value: myShare))
                                        .bold()
                                }
                                
                                
                                HStack {
                                    Text("\("day".localizeString()): \(overhead.getDayOfPay())")
                                        .font(.footnote)
                                Spacer()
                                    Text(Utility.doubleToLocalCurrency(value: overhead.amount))
                                        .font(.footnote)
                                }
                                
                                HStack {
                                    Text("balanceOnAccount")
                                        .font(.caption)
                                Spacer()
                                    Text(Utility.doubleToLocalCurrency(value: balanceOnAccount))
                                        .font(.caption)
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
