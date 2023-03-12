//
//  SettingsRowView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-18.
//

import SwiftUI

struct Setting: Identifiable {
    let id = UUID()

    let name: LocalizedStringKey
    let imgName: String
    var view: AnyView
}

struct SettingsRowsView: View {
    private let settings: [Setting] = [
        Setting(
            name: "general",
            imgName: "gear",
            view: AnyView(GeneralSettingsView())
        ),
        Setting(
            name: "friends",
            imgName: "person.2",
            view: AnyView(FriendsView())
        ),
        Setting(
            name: "quickBalance",
            imgName: "creditcard",
            view: AnyView(QuickBalanceView())
        ),
        Setting(
            name: "budget",
            imgName: "dollarsign",
            view: AnyView(BudgetView())
        ),
        Setting(
            name: "transactionCategories",
            imgName: "arrow.left.arrow.right",
            view: AnyView(TransactionCategoriesView())
        )
    ]

    var body: some View {
        ForEach(settings) { setting in
            NavigationLink {
                setting.view
            } label: {
                Label(setting.name, systemImage: setting.imgName)
            }
        }
    }
}

struct SettingsRowsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsRowsView()
            .environmentObject(AuthViewModel())
    }
}
