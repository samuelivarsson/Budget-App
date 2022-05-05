//
//  ParticipantsView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-05-01.
//

import SwiftUI

struct ParticipantsView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Friend.name, ascending: true)],
        animation: .default)
    private var friends: FetchedResults<Friend>
    
    var body: some View {
        ForEach(friends, id: \.self) { friend in
            HStack {
                
                Text(friend.name ?? "ajdå")
            }
        }
    }
}

struct ParticipantsView_Previews: PreviewProvider {
    static var previews: some View {
        ParticipantsView()
    }
}
