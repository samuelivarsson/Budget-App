//
//  WelcomeScreenView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-14.
//

import SwiftUI

struct WelcomeScreenView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var firestoreViewModel: FirestoreViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @AppStorage("welcomeScreenShown") private var welcomeScreenShown: Bool = false
    
    var body: some View {
        NavigationView {
            TabView {
                LoginView()
                TransactionCategoriesView()
            }
            .navigationTitle("welcome")
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .toolbar {
                ToolbarItem {
                    Button {
                        welcomeScreenShown = true
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}

struct WelcomeScreenView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeScreenView()
    }
}
