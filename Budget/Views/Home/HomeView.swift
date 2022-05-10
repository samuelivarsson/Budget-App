//
//  HomeView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-12.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.red
            }
            .navigationTitle("home")
            .toolbar {
                ToolbarItem {
                    NavigationLink {
                        NotificationsView()
                    } label: {
                        Image(systemName: "bell")
                    }
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
