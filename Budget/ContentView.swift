//
//  ContentView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-12.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("welcomeScreenShown") private var welcomeScreenShown: Bool = false
    @EnvironmentObject private var viewModel: AuthViewModel
    @EnvironmentObject private var errorHandling: ErrorHandling
    
    var body: some View {
        VStack {
            switch viewModel.state {
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
        .onAppear {
            viewModel.state = viewModel.getState
            viewModel.errorHandling = errorHandling
        }
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
            HistoryView().tabItem {
                Image(systemName: "clock")
                Text("history")
            }
            SettingsView().tabItem {
                Image(systemName: "gear")
                Text("settings")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .environmentObject(AuthViewModel())
                .environmentObject(ErrorHandling())
            ContentView()
                .preferredColorScheme(.dark)
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .environmentObject(AuthViewModel())
                .environmentObject(ErrorHandling())
        }
    }
}

extension String {
    func localizeString(string: String) -> String {
        let path = Bundle.main.path(forResource: string, ofType: "lproj")
        let bundle = Bundle(path: path!)
        return NSLocalizedString(self, tableName: nil, bundle: bundle!, value: "", comment: "")
    }
}
