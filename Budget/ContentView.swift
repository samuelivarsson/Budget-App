//
//  ContentView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-12.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("welcomeScreenShown") private var welcomeScreenShown: Bool = false
    
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var fsViewModel: FirestoreViewModel
    @EnvironmentObject private var notificationsViewModel: NotificationsViewModel
    @EnvironmentObject private var transactionsViewModel: TransactionsViewModel
    @EnvironmentObject private var standingsViewModel: StandingsViewModel

    var body: some View {
        VStack {
            switch authViewModel.state {
            case .signedIn:
                if welcomeScreenShown {
                    content
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
            self.userViewModel.fetchData { error in
                if let error = error {
                    self.errorHandling.handle(error: error)
                    return
                }

                // Success
                    self.transactionsViewModel.fetchData(monthStartsOn: self.userViewModel.user.monthStartsOn) { error in
                        if let error = error {
                            self.errorHandling.handle(error: error)
                            return
                        }

                        // Success
                        self.standingsViewModel.fetchData { error in
                            if let error = error {
                                self.errorHandling.handle(error: error)
                                return
                            }
                            
                            // Success
                            self.standingsViewModel.firstLoadFinished = true
                        }
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

extension String {
    func localizeString() -> String {
        return NSLocalizedString(self, comment: "")
    }
}
