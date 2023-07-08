//
//  QuickBalanceAccountView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-24.
//

import SwiftUI

struct QuickBalanceAccountView: View {
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var quickBalanceViewModel: QuickBalanceViewModel
    
    @State var quickBalanceAccount: QuickBalanceAccount
    @State var add: Bool = false
    @State private var apiCallsFinished: Bool = true
    @State private var chooseButtonPressed: Bool = false
    @State private var addButtonPressed: Bool = false
    @State private var mobileBankIdResponse: MobileBankIDResponse = .getDummyResponse()
    @State private var quickBalanceAccountsResponse: QuickBalanceAccountsResponse = .getDummyResponse()
    @State private var quickBalanceAccountResponse: QuickBalanceAccountsResponse.QuickBalanceAccountResponse = .getDummyResponse()
    
    init(add: Bool) {
        self._quickBalanceAccount = State(initialValue: QuickBalanceAccount.getDummyAccount())
        self._add = State(initialValue: add)
        self._apiCallsFinished = State(initialValue: false)
    }
    
    init(quickBalanceAccount: QuickBalanceAccount) {
        self._quickBalanceAccount = State(initialValue: quickBalanceAccount)
    }
    
    var body: some View {
        Form {
            if self.apiCallsFinished {
                Section {
                    HStack {
                        Text("name")
                        Spacer()
                        Text(self.quickBalanceAccount.name)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("subscriptionId")
                        Spacer()
                        Text(self.quickBalanceAccount.subscriptionId)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker("budgetAccount", selection: self.$quickBalanceAccount.budgetAccountId) {
                        ForEach(self.userViewModel.getAccountsSorted()) { account in
                            Text(account.name).tag(account.id)
                        }
                    }
                    .onLoad {
                        if self.add {
                            guard let first = self.userViewModel.getAccountsSorted().first else {
                                let info = "Found nil when extracting first in onLoad in QuickBalanceAccountView"
                                self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
                                return
                            }
                            self.quickBalanceAccount.budgetAccountId = first.id
                        }
                    }
                }
                
                Section {
                    if self.addButtonPressed {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        Button {
                            if self.add {
                                self.addAccount()
                            } else {
                                self.editAccount()
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
            } else {
                Section {
                    Picker("chooseAnAccount", selection: self.$quickBalanceAccountResponse) {
                        ForEach(self.quickBalanceAccountsResponse.accounts, id: \.quickBalanceSubscription.id) { quickBalanceAccountResponse in
                            Text(quickBalanceAccountResponse.name).tag(quickBalanceAccountResponse)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section {
                    if self.chooseButtonPressed {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        Button {
                            self.chooseAccount()
                        } label: {
                            HStack {
                                Spacer()
                                Text("choose")
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("quickBalanceAccount")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if self.add {
                MobileBankID.initAuth { mobileBankIdResponse, error in
                    if let error = error {
                        self.errorHandling.handle(error: error)
                        return
                    }
                    
                    guard let mobileBankIdResponse = mobileBankIdResponse else {
                        let info = "Found nil when extracting mobileBankIdResponse in onLoad in QuickBalanceAccountView"
                        self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
                        return
                    }
                    
                    // Success
                    self.mobileBankIdResponse = mobileBankIdResponse
                    AppOpener.openBankId(autoStartToken: mobileBankIdResponse.autoStartToken) { error in
                        if let error = error {
                            self.errorHandling.handle(error: error)
                            return
                        }
                        
                        // Success
                    }
                }
            }
        }
        .onOpenURL { url in
            self.handleUrlOpen(url: url)
        }
    }
    
    private func addAccount() {
        if self.addButtonPressed {
            return
        }
        self.addButtonPressed = true
        
        self.userViewModel.addQuickBalanceAccount(account: self.quickBalanceAccount) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
            self.presentationMode.wrappedValue.dismiss()
            MobileBankID.terminate { error in
                if let error = error {
                    self.errorHandling.handle(error: error)
                    return
                }
                
                // Success
                self.quickBalanceViewModel.fetchQuickBalanceFromApi(quickBalanceAccounts: self.userViewModel.user.quickBalanceAccounts) { error in
                    if let error = error {
                        self.errorHandling.handle(error: error)
                        return
                    }
                
                    // Success
                }
            }
        }
    }
    
    private func editAccount() {
        if self.addButtonPressed {
            return
        }
        self.addButtonPressed = true
        
        self.userViewModel.editQuickBalanceAccount(account: self.quickBalanceAccount) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
            self.presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func chooseAccount() {
        if self.chooseButtonPressed {
            return
        }
        self.chooseButtonPressed = true
        
        MobileBankID.quickBalanceSubscription(quickbalanceSubscriptionID: self.quickBalanceAccountResponse.quickBalanceSubscription.id) { quickBalanceSubscriptionResponse, error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            guard let quickBalanceSubscriptionResponse = quickBalanceSubscriptionResponse else {
                let info = "Found nil when extracting quickBalanceSubscriptionResponse in chooseAccount in QuickBalanceAccountView"
                self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
                return
            }
            
            // Success
            self.quickBalanceAccount.subscriptionId = quickBalanceSubscriptionResponse.subscriptionId
            self.quickBalanceAccount.name = self.quickBalanceAccountResponse.name
            self.apiCallsFinished = true
        }
    }
    
    private func handleUrlOpen(url: URL) {
        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
        if let queryItems = urlComponents?.queryItems {
            for queryItem in queryItems {
                if let value = queryItem.value {
                    if queryItem.name == "sourceApplication" && value != "bankid" {
                        return
                    }
                }
            }
            
            MobileBankID.verify { error in
                if let error = error {
                    self.errorHandling.handle(error: error)
                    return
                }
                
                // Success
                MobileBankID.profileList { error in
                    if let error = error {
                        self.errorHandling.handle(error: error)
                        return
                    }
                    
                    // Success
                    MobileBankID.quickBalanceAccounts { quickBalanceAccountsResponse, error in
                        if let error = error {
                            self.errorHandling.handle(error: error)
                            return
                        }
                        
                        guard let quickBalanceAccountsResponse = quickBalanceAccountsResponse else {
                            let info = "Found nil when extracting quickBalanceAccountsResonse in handleUrlOpen in QuickBalanceAccountView"
                            self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
                            return
                        }
                    
                        // Success
                        self.quickBalanceAccountsResponse = quickBalanceAccountsResponse
                        if self.add {
                            guard let first = self.quickBalanceAccountsResponse.accounts.first else {
                                let info = "Found nil when extracting first in onLoad in QuickBalanceAccountView (2)"
                                self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
                                return
                            }
                            self.quickBalanceAccountResponse = first
                        }
                    }
                }
            }
        }
    }
}

// struct QuickBalanceAccountView_Previews: PreviewProvider {
//    static var previews: some View {
//        QuickBalanceAccountView()
//    }
// }
