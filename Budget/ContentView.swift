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
    @EnvironmentObject private var tabRouter: TabRouter

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
        TabView(selection: self.$tabRouter.selectedTab) {
            HomeView().tabItem {
                Image(systemName: "house")
                Text("home")
            }
            .tag(TabRouter.Tab.home)
            TransactionsView().tabItem {
                Image(systemName: "arrow.left.arrow.right")
                Text("transactions")
            }
            .tag(TabRouter.Tab.transactions)
            StandingsView().tabItem {
                Image(systemName: "person.2")
                Text("standings")
            }
            .tag(TabRouter.Tab.standings)
            HistoryView().tabItem {
                Image(systemName: "clock")
                Text("history")
            }
            .tag(TabRouter.Tab.history)
            SettingsView().tabItem {
                Image(systemName: "gear")
                Text("settings")
            }
            .tag(TabRouter.Tab.settings)
        }
        .onLoad {
            do {
                try Auth.auth().useUserAccessGroup("\(Secrets.teamId).com.samuelivarsson.Budget")
            } catch let error as NSError {
                self.errorHandling.handle(error: error)
            }
        }
        .onAppear {
            self.fetchData { error in
                if let error = error {
                    self.errorHandling.handle(error: error)
                    Utility.firstLoadFinished = true
                    return
                }
            }
        }
        .onOpenURL { url in
            self.handleUrlOpen(url: url)
        }
    }

    private func fetchData(completion: @escaping (Error?) -> Void) {
        guard !Utility.firstLoadFinished else {
            print("Skipping data fetch - already finished")
            completion(nil)
            return
        }
        guard !Utility.firstLoadInProgress else {
            print("Skipping data fetch - in progress")
            Utility.firstLoadCompletions.append(completion)
            return
        }

        print("Starting data fetch...")

        Utility.firstLoadInProgress = true
        Utility.firstLoadCompletions.append(completion)

        // Start parallel tasks
        self.notificationsViewModel.fetchData { error in
            if let error = error {
                self.errorHandling.handle(error: error)
            }
        }

        var alreadyCompleted = false
        self.userViewModel.fetchData { error in
            guard !alreadyCompleted else {
                print("🚨 Completion already called once — skipping duplicate")
                return
            }
            alreadyCompleted = true
            print("User data fetched")
            if let error = error {
                Utility.firstLoadInProgress = false
                let completions = Utility.firstLoadCompletions
                Utility.firstLoadCompletions.removeAll()
                completions.forEach { $0(error) }
                return
            }

            // Fire quickBalance fetch in parallel
            self.quickBalanceViewModel.fetchQuickBalanceFromApi(
                quickBalanceAccounts: self.userViewModel.user.quickBalanceAccounts
            ) { error in
                if let error = error {
                    self.errorHandling.handle(error: error)
                }
            }

//            self.transactionsViewModel.fetchData(monthStartsOn: self.userViewModel.user.budget.monthStartsOn, monthsBack: 1) { error in
//                if let error = error {
//                    completion(error)
//                    return
//                }
//
//                // Success
//                self.standingsViewModel.fetchData { error in
//                    if let error = error {
//                        completion(error)
//                        return
//                    }
//
//                    // Success
//                    self.nextMonthChangesViewModel.fetchData { error in
//                        if let error = error {
//                            completion(error)
//                            return
//                        }
//
//                        // Success
//                        self.historyViewModel.fetchData { error in
//                            if let error = error {
//                                completion(error)
//                                return
//                            }
//
//                            // Success
//                            self.saveIfNeeded { error in
//                                if let error = error {
//                                    completion(error)
//                                    return
//                                }
//
//                                // Success
//                                Utility.firstLoadFinished = true
//                                Utility.firstLoadInProgress = false
//                                completion(nil)
//                            }
//                        }
//                    }
//                }
//            }

            let sequence: [(@escaping (Error?) -> Void) -> Void] = [
                { done in self.transactionsViewModel.fetchData(monthStartsOn: self.userViewModel.user.budget.monthStartsOn, monthsBack: 1, completion: done) },
                { done in self.standingsViewModel.fetchData(completion: done) },
                { done in self.historyViewModel.fetchData(completion: done) },
                { done in self.saveIfNeeded(completion: done) }
            ]

            Utility.runTasksInSequence(sequence) { error in
                if let error = error {
                    Utility.firstLoadInProgress = false
                    let completions = Utility.firstLoadCompletions
                    Utility.firstLoadCompletions.removeAll()
                    completions.forEach { $0(error) }
                    return
                }

                print("First load finished")

                Utility.firstLoadFinished = true
                Utility.firstLoadInProgress = false
                let completions = Utility.firstLoadCompletions
                Utility.firstLoadCompletions.removeAll()
                completions.forEach { $0(nil) }
            }
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

        let saveDate = Date.now
        self.userViewModel.user.lastSaveDate = saveDate

        // Save this months category amounts and accumulate the realised totals per type
        var categoryHistories: [CategoryHistory] = .init()
        var actualIncome: Double = 0
        var actualExpenses: Double = 0
        var actualSavings: Double = 0
        for transactionCategory in self.userViewModel.user.budget.transactionCategories {
            let totalAmount = self.transactionsViewModel.getSpent(user: self.userViewModel.user, transactionCategory: transactionCategory, monthsBack: 1)
            categoryHistories.append(CategoryHistory(categoryId: transactionCategory.id, categoryName: transactionCategory.name, totalAmount: totalAmount, saveDate: saveDate, userId: self.userViewModel.user.id, categoryType: transactionCategory.type))
            switch transactionCategory.type {
            case .income: actualIncome += totalAmount
            case .expense: actualExpenses += totalAmount
            case .saving: actualSavings += totalAmount
            }
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
            let balance = self.userViewModel.getBalance(accountId: account.id, spent: spent, incomes: incomes, monthsBack: 1)

            accountHistories.append(AccountHistory(accountId: account.id, accountName: account.name, balance: balance, saveDate: saveDate, userId: self.userViewModel.user.id))

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

        // Save this months planned budget figures (income / fixed costs / scheduled
        // saving) so the History view can show a truthful Netto over time — these
        // only ever live in the current budget config otherwise.
        let budget = self.userViewModel.user.budget
        let monthlySummary = MonthlySummary(
            income: budget.income,
            fixedCosts: budget.getOverheadsAmount(monthsBack: 1),
            scheduledSavings: budget.getSavings(),
            actualIncome: actualIncome,
            actualExpenses: actualExpenses,
            actualSavings: actualSavings,
            saveDate: saveDate,
            userId: self.userViewModel.user.id
        )

        print("1")
        var hasCalledCompletion = false

        // Save the histories
        self.historyViewModel.addHistories(accountHistories: accountHistories, categoryHistories: categoryHistories, monthlySummary: monthlySummary) { error in
            print("2")
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }

            // Success
            self.userViewModel.setUserData { error in
                print("3")
                if let error = error {
                    completion(error)
                    return
                }

                // Success
                if !hasCalledCompletion {
                    print("4")
                    hasCalledCompletion = true
                    completion(nil)
                }
            }
        }
    }

    private func handleUrlOpen(url: URL) {
        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
        if let queryItems = urlComponents?.queryItems {
            var kind = ""
            for queryItem in queryItems {
                if let value = queryItem.value {
                    if queryItem.name == "sourceApplication", value == "transactionFromUrl" {
                        if Utility.firstLoadFinished {
                            self.tabRouter.selectedTab = .transactions
                            self.tabRouter.appStartFromUrl = url
                            return
                        }

                        self.fetchData { error in
                            if let error = error {
                                self.errorHandling.handle(error: error)
                                return
                            }

                            self.tabRouter.selectedTab = .transactions
                            self.tabRouter.appStartFromUrl = url
                        }
                    }
                    if queryItem.name == "sourceApplication", value != "widget" {
                        return
                    }
                    if queryItem.name == "kind", !value.isEmpty {
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
