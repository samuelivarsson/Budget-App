//
//  MonthStartsOnView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-26.
//

import SwiftUI

struct MonthStartsOnView: View {
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    @AppStorage("monthStartsOn") private var monthStartsOn = 25
    @State private var day: Int = 0
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("monthStartsOn")
                    Spacer()
                    Picker("monthStartsOn", selection: $day) {
                        ForEach(1..<29) {
                            Text("\($0)")
                        }
                    }
                    .pickerStyle(.menu)
                    .onAppear {
                        day = monthStartsOn-1
                    }
                }
            }
            
            Button {
                monthStartsOn = day+1
                presentationMode.wrappedValue.dismiss()
            } label: {
                HStack {
                    Spacer()
                    Text("apply")
                    Spacer()
                }
            }
        }
        .navigationTitle("monthStartsOn")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MonthStartsOnView_Previews: PreviewProvider {
    static var previews: some View {
        MonthStartsOnView()
    }
}
