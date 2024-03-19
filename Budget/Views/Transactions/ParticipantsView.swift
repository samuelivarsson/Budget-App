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
    @Binding var splitOption: SplitOption
    @Binding var participants: [Participant]
    @Binding var payer: String
    @Binding var hasWritten: [String]
    
    var action: TransactionAction
    
    private let friendText: Font = .footnote
    
    var body: some View {
        if action != .view {
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
        }
            
        HStack {
            Text("payer")
            Spacer()
            Picker("", selection: self.$payer) {
                ForEach(self.participants, id: \.userId) { participant in
                    Text(participant.userId == self.userViewModel.user.id ? "you".localizeString() : participant.userName)
                        .tag(participant.userId)
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
            
        HStack {
            Text("splitOption")
            Spacer()
            Picker("", selection: self.$splitOption) {
                ForEach(SplitOption.allCases, id: \.self) { splitOption in
                    Text(splitOption.description()).tag(splitOption)
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
            
        // Use a ForEach loop to display a list of participants
        ForEach(Array($participants.enumerated()), id: \.element.id) { _, $participant in
            ParticipantView(participant: $participant, splitOption: self.$splitOption, participants: self.$participants, totalAmount: self.$totalAmount, hasWritten: self.$hasWritten, action: self.action)
        }
        .onDelete(perform: deleteParticipants)
        .onChange(of: participants.count) { _ in
            DispatchQueue.main.async {
                if let errorString = Utility.setAmountPerParticipant(splitOption: self.splitOption, participants: self.$participants, totalAmount: self.totalAmount, hasWritten: self.hasWritten, myUserId: self.userViewModel.user.id) {
                    self.errorHandling.handle(error: ApplicationError.unexpectedNil(errorString))
                }
            }
        }
        .onChange(of: splitOption) { newValue in
            DispatchQueue.main.async {
                if newValue == .meEverything {
                    self.hasWritten = []
                    if let notMe = self.participants.first(where: { $0.userId != self.userViewModel.user.id }) {
                        self.payer = notMe.userId
                    }
                }
                if let errorString = Utility.setAmountPerParticipant(splitOption: self.splitOption, participants: self.$participants, totalAmount: self.totalAmount, hasWritten: self.hasWritten, myUserId: self.userViewModel.user.id) {
                    self.errorHandling.handle(error: ApplicationError.unexpectedNil(errorString))
                }
            }
        }
    }
    
    private func deleteParticipants(offsets: IndexSet) {
        withAnimation {
            self.participants.remove(atOffsets: offsets)
            self.hasWritten.removeAll { userId in
                !self.participants.contains(where: { $0.userId == userId })
            }
        }
    }
}
