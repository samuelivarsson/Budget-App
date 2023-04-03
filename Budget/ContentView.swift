//
//  ContentView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-12.
//

import Firebase
import SwiftUI
import WidgetKit

struct ContentView: View {
    @AppStorage("welcomeScreenShown") private var welcomeScreenShown: Bool = false

    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var fsViewModel: FirestoreViewModel
    @EnvironmentObject private var notificationsViewModel: NotificationsViewModel
    @EnvironmentObject private var transactionsViewModel: TransactionsViewModel
    @EnvironmentObject private var standingsViewModel: StandingsViewModel
    @EnvironmentObject private var historyViewModel: HistoryViewModel
    @EnvironmentObject private var quickBalanceViewModel: QuickBalanceViewModel

    var body: some View {
        VStack {
            switch self.authViewModel.state {
            case .signedIn:
                if self.welcomeScreenShown {
                    self.content
                } else {
                    WelcomeScreenView()
                }
            case .signedOut:
                SignInView()
            }
        }
        .navigationViewStyle(.stack)
    }

    private var content: some View {
        TabView {
            HomeView().tabItem {
                Image(systemName: "house")
                Text("home")
            }
            TransactionsView().tabItem {
                Image(systemName: "arrow.left.arrow.right")
                Text("transactions")
            }
            StandingsView().tabItem {
                Image(systemName: "person.2")
                Text("standings")
            }
            HistoryView().tabItem {
                Image(systemName: "clock")
                Text("history")
            }
            SettingsView().tabItem {
                Image(systemName: "gear")
                Text("settings")
            }
        }
        .onLoad {
            do {
                try Auth.auth().useUserAccessGroup("\(Secrets.teamId).com.samuelivarsson.Budget")
            } catch let error as NSError {
                self.errorHandling.handle(error: error)
            }
        }
        .onAppear {
            self.fetchData()
        }
        .onOpenURL { url in
            self.handleUrlOpen(url: url)
        }
    }

    private func fetchData() {
        if Utility.firstLoadFinished {
            print("nope")
            return
        }
        self.userViewModel.fetchData { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }

            // Success
            if Utility.firstLoadFinished {
                return
            }
            self.transactionsViewModel.fetchData(monthStartsOn: self.userViewModel.user.budget.monthStartsOn, monthsBack: 1) { error in
                if let error = error {
                    self.errorHandling.handle(error: error)
                    return
                }

                // Success
                if Utility.firstLoadFinished {
                    return
                }
                self.standingsViewModel.fetchData { error in
                    if let error = error {
                        self.errorHandling.handle(error: error)
                        return
                    }

                    // Success
                    if Utility.firstLoadFinished {
                        return
                    }
                    self.historyViewModel.fetchData { error in
                        if let error = error {
                            self.errorHandling.handle(error: error)
                            return
                        }

                        // Success
                        if Utility.firstLoadFinished {
                            return
                        }
                        Utility.firstLoadFinished = true
                        self.saveIfNeeded { error in
                            if let error = error {
                                self.errorHandling.handle(error: error)
                                return
                            }

                            // Success
                        }
                    }
                }
            }
            self.quickBalanceViewModel.fetchQuickBalanceFromApi(quickBalanceAccounts: self.userViewModel.user.quickBalanceAccounts) { error in
                if let error = error {
                    self.errorHandling.handle(error: error)
                    return
                }

                // Success
            }
        }
        self.notificationsViewModel.fetchData { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }

            // Success
        }
    }

    private func isSaveNeeded() -> Bool {
        let referenceDate = Utility.getBudgetPeriod(monthStartsOn: self.userViewModel.user.budget.monthStartsOn).0
        print("isSaveNeeded: \(self.userViewModel.user.lastSaveDate < referenceDate)")
        return self.userViewModel.user.lastSaveDate < referenceDate
    }

    private func saveIfNeeded(completion: @escaping (Error?) -> Void) {
        guard self.isSaveNeeded() else {
            completion(nil)
            return
        }

        // Save this months category amounts
        var categoryHistories: [CategoryHistory] = .init()
        for transactionCategory in self.userViewModel.user.budget.transactionCategories {
            let totalAmount = self.transactionsViewModel.getSpent(user: self.userViewModel.user, transactionCategory: transactionCategory, monthsBack: 1)
            categoryHistories.append(CategoryHistory(categoryId: transactionCategory.id, categoryName: transactionCategory.name, totalAmount: totalAmount, saveDate: Date.now, userId: self.userViewModel.user.id))
        }

        // Save this months final account balances
        var accountHistories: [AccountHistory] = .init()
        let mainOverheadAccountId = self.userViewModel.user.budget.getMainAccountId(type: .overhead)
        let mainTransactionAccountId = self.userViewModel.user.budget.getMainAccountId(type: .transaction)
        let mainSavingsAccountId = self.userViewModel.user.budget.getMainAccountId(type: .saving)
        var mainTransactionAccountBalance: Double = 0
        for account in self.userViewModel.getAccounts() {
            if account.id == mainOverheadAccountId {
                continue
            }
            let spent = self.transactionsViewModel.getSpent(user: self.userViewModel.user, accountId: account.id, monthsBack: 1)
            let incomes = self.transactionsViewModel.getIncomes(user: self.userViewModel.user, accountId: account.id, monthsBack: 1)
            let balance = self.userViewModel.getBalance(accountId: account.id, spent: spent, incomes: incomes)

            accountHistories.append(AccountHistory(accountId: account.id, accountName: account.name, balance: balance, saveDate: Date.now, userId: self.userViewModel.user.id))

            // Set new base amounts
            if account.id != mainTransactionAccountId {
                var newAccount = account
                newAccount.baseAmount = balance
                self.userViewModel.user.budget.accounts = self.userViewModel.user.budget.accounts.filter { $0.id != account.id } + [newAccount]
            } else {
                mainTransactionAccountBalance = balance
            }
        }

        // Give remaining money of main transactions account to main savings account
        for i in 0 ..< accountHistories.count {
            if accountHistories[i].accountId == mainSavingsAccountId {
                accountHistories[i].balance += mainTransactionAccountBalance
                guard let account = self.userViewModel.getAccountsSorted(type: .saving).filter({ $0.main }).first else {
                    let info = "Found nil when extracting mainSavingsAccount in saveIfNeeded in ContentView"
                    completion(ApplicationError.unexpectedNil(info))
                    return
                }
                var newAccount = account
                newAccount.baseAmount = accountHistories[i].balance
                self.userViewModel.user.budget.accounts = self.userViewModel.user.budget.accounts.filter { $0.id != account.id } + [newAccount]
            }
        }

        // Save the histories
        self.historyViewModel.addHistories(accountHistories: accountHistories, categoryHistories: categoryHistories) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }

            // Success
            self.userViewModel.user.lastSaveDate = Date.now
            self.userViewModel.setUserData { error in
                if let error = error {
                    completion(error)
                    return
                }

                // Success
            }
        }
    }

    private func handleUrlOpen(url: URL) {
        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
        if let queryItems = urlComponents?.queryItems {
            var kind = ""
            for queryItem in queryItems {
                if let value = queryItem.value {
                    if queryItem.name == "sourceApplication" && value != "widget" {
                        return
                    }
                    if queryItem.name == "kind" && !value.isEmpty {
                        kind = value
                    }
                }
            }
            // Reload timeline
            WidgetCenter.shared.reloadTimelines(ofKind: kind)
            // Close app
            UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .environmentObject(AuthViewModel())
                .environmentObject(ErrorHandling())
            ContentView()
                .preferredColorScheme(.dark)
                .environmentObject(AuthViewModel())
                .environmentObject(ErrorHandling())
        }
    }
}
