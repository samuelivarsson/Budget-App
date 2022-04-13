//
//  SettingsView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-12.
//

import SwiftUI

private var settingsProvider = SettingsProvider()

struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                ForEach(settingsProvider.getSettings()) { setting in
                    NavigationLink {
                        setting.view
                    } label: {
                        Label(setting.name, systemImage: setting.imgName)
                    }
                }
            }
            .navigationTitle("settings")
        }
        .navigationViewStyle(.stack)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
