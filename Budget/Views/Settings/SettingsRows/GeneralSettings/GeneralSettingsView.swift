//
//  GeneralSettingsView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-26.
//

import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage("monthStartsOn") private var monthStartsOn = 25
    
    var body: some View {
        Form {
            NavigationLink {
                MonthStartsOnView()
            } label: {
                HStack {
                    Text("monthStartsOn")
                    Spacer()
                    Text("\(monthStartsOn)")
                }
            }
        }
        .navigationTitle("general")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GeneralSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralSettingsView()
    }
}
