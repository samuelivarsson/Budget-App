//
//  ParticipantsView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-05-01.
//

import SwiftUI

struct ParticipantsView: View {
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel
    
    @Binding var totalAmount: Double
    @Binding var splitEvenly: Bool
    @Binding var participants: [Participant]
    @Binding var payer: String
    var isInputActive: FocusState<Bool>.Binding
    
    var action: TransactionAction
    
    private let friendText: Font = .footnote
    
    var body: some View {
        if self.action != .view {
            HStack(spacing: 10) {
                Text("addFriend")
                
                Spacer()
                    
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        let friends = self.userViewModel.getFavouritesSorted(exceptFor: self.participants)
                        ForEach(friends, id: \.id) { friend in
                            Button {
                                self.participants.append(Participant(userId: friend.id, userName: friend.name))
                            } label: {
                                Text(friend.name)
                                    .font(self.friendText)
                                    .lineLimit(1)
                            }
                        }
                        .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .padding(EdgeInsets(top: 5, leading: 0, bottom: 0.8, trailing: 0))
                    }
                }
                .frame(maxWidth: .infinity)
                .scaledToFit()
                
                Divider()
                
                NavigationLink {
                    SeeAllFriendsView(participants: self.$participants)
                } label: {
                    Text("seeAll")
                        .scaledToFit()
                        .foregroundStyle(Color.accentColor)
                }
                .frame(width: 70)
                .padding(0)
                .buttonStyle(PlainButtonStyle())
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
        
        HStack {
            Text("payer")
            Spacer()
            Picker("", selection: self.$payer) {
                ForEach(self.participants, id: \.userId) { participant in
                    Text(participant.userId == self.userViewModel.user.id ? "you".localizeString() : participant.userName).tag(participant.userId)
                        .minimumScaleFactor(0.1)
                        .lineLimit(1)
                }
            }
            .disabled(self.action == .view)
            .onLoad {
                if self.action == .add {
                    guard let first = self.participants.first else {
                        let info = "Found nil when extracting first in onLoad in payer picker in ParticipantsView"
                        self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
                        return
                    }
                    
                    self.payer = first.userId
                }
            }
        }
            
        // Use a Toggle to allow the user to turn splitEvenly on or off
        Toggle("splitEvenly", isOn: self.$splitEvenly)
            .disabled(self.action == .view)
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
                Text(participant.userId == self.userViewModel.user.id ? "you".localizeString() : participant.userName)
                Spacer()
                if self.splitEvenly || self.action == .view {
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
            .deleteDisabled(participant.userId == self.userViewModel.user.id || self.action == .view)
        }
        .onDelete(perform: deleteParticipants)
    }
    
    private func deleteParticipants(offsets: IndexSet) {
        withAnimation {
            self.participants.remove(atOffsets: offsets)
        }
    }
}
