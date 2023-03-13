//
//  ParticipantsView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-05-01.
//

import SwiftUI

struct ParticipantsView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    
    @Binding var totalAmount: Double
    @Binding var splitEvenly: Bool
    @Binding var participants: [Participant]
    @Binding var payer: String
    var isInputActive: FocusState<Bool>.Binding
    
    private let friendText: Font = .footnote
    
    var body: some View {
        HStack(spacing: 10) {
            Text("friends")
            
            Spacer()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    let friends = self.userViewModel.getAllFriendsSorted(exceptFor: self.participants)
                    ForEach(friends, id: \.id) { friend in
                        Button {
                            self.participants.append(Participant(userId: friend.id, userName: friend.name))
                        } label: {
                            Text(friend.name)
                                .font(self.friendText)
                                .lineLimit(1)
                        }
                        .onChange(of: self.participants) { _ in
                            // If splitEvenly is true, divide the total amount evenly among the participants
                            if self.splitEvenly {
                                let amountPerParticipant = Utility.doubleToTwoDecimalsFloored(value: self.totalAmount / Double(self.participants.count))
                                var val = self.totalAmount
                                for i in (0 ..< self.participants.count).reversed() {
                                    self.participants[i].amount = Utility.doubleToTwoDecimals(value: i == 0 ? val : amountPerParticipant)
                                    val -= amountPerParticipant
                                }
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 0.6, trailing: 0))
                }
            }
        }
        
        Picker("payer", selection: self.$payer) {
            ForEach(self.participants, id: \.userId) { participant in
                Text(participant.userName).tag(participant.userId)
            }
        }
            
        // Use a Toggle to allow the user to turn splitEvenly on or off
        Toggle("splitEvenly", isOn: self.$splitEvenly)
            .onChange(of: self.splitEvenly) { _ in
                // If splitEvenly is true, divide the total amount evenly among the participants
                if self.splitEvenly {
                    let amountPerParticipant = Utility.doubleToTwoDecimalsFloored(value: self.totalAmount / Double(self.participants.count))
                    var val = self.totalAmount
                    for i in (0 ..< self.participants.count).reversed() {
                        self.participants[i].amount = Utility.doubleToTwoDecimals(value: i == 0 ? val : amountPerParticipant)
                        val -= amountPerParticipant
                    }
                }
            }
            
        // Use a ForEach loop to display a list of participants
        ForEach(self.$participants, id: \.id) { $participant in
            HStack {
                Text(participant.me ? "me".localizeString() : participant.userName)
                Spacer()
                if self.splitEvenly {
                    Text(Utility.doubleToLocalCurrency(value: participant.amount))
                        .padding(5)
                } else {
                    HStack {
                        TextField(Utility.currencyFormatterNoSymbol.string(from: 0.0) ?? "0", value: $participant.amount, formatter: Utility.currencyFormatterNoSymbolNoZeroSymbol)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused(self.isInputActive)
                            .padding(5)
                            .background(Color.tertiaryBackground)
                            .cornerRadius(8)
                            .fixedSize()
                        
                        Text(Utility.currencyFormatter.currencySymbol)
                    }
                }
            }
            .deleteDisabled(participant.me)
        }
        .onDelete(perform: deleteParticipants)
    }
    
    private func deleteParticipants(offsets: IndexSet) {
        withAnimation {
            self.participants.remove(atOffsets: offsets)
        }
    }
}
