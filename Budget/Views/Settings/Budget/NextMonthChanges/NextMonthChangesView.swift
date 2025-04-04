//
//  NextMonthChangesView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2024-08-07.
//

import Foundation
import SwiftUI

struct NextMonthChangesView: View {
    @EnvironmentObject private var nextMonthChangesViewModel: NextMonthChangesViewModel
    
    var body: some View {
        Form {
            Section {
                ForEach(self.getOverheadChanges(), id: \.self.id) { overhead in
                    NavigationLink {
                        OverheadView(overhead: overhead, nextMonthChanges: true)
                    } label: {
                        Text(overhead.name)
                    }
                }
            } header: {
                Text("overhead")
            }
        }
    }
    
    private func getOverheadChanges() -> [Overhead] {
        var result: [Overhead] = .init()
        for change in self.nextMonthChangesViewModel.changes {
            if let overhead = change as? Overhead {
                result.append(overhead)
            }
        }
        return result
    }
}
