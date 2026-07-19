//
//  AddTransactionComponents.swift
//  Budget
//
//  Reusable pieces for the redesigned add/edit transaction screen.
//

import SwiftUI
import MathParser

// MARK: - Person avatar helpers

enum PersonPalette {
    static let colors: [Color] = [
        Color(red: 0.753, green: 0.541, blue: 0.369), // C08A5E
        Color(red: 0.369, green: 0.620, blue: 0.431), // 5E9E6E
        Color(red: 0.541, green: 0.447, blue: 0.753), // 8A72C0
        Color(red: 0.780, green: 0.482, blue: 0.322), // C77B52
        Color(red: 0.310, green: 0.620, blue: 0.682), // 4F9EAE
        Color(red: 0.431, green: 0.525, blue: 0.753), // 6E86C0
        Color(red: 0.369, green: 0.561, blue: 0.690), // 5E8FB0
        Color(red: 0.690, green: 0.431, blue: 0.557), // B06E8E
    ]
    static func color(for id: String) -> Color {
        var hash = 0
        for u in id.unicodeScalars { hash = (hash &* 31 &+ Int(u.value)) & 0x7fffffff }
        return colors[hash % colors.count]
    }
}

func personInitials(_ name: String) -> String {
    let parts = name.split(separator: " ")
    if parts.count > 1 {
        return (String(parts[0].prefix(1)) + String(parts[1].prefix(1))).uppercased()
    }
    return String(name.prefix(2)).uppercased()
}

struct PersonAvatar: View {
    let name: String
    let id: String
    var isYou: Bool = false
    var size: CGFloat = 40
    var body: some View {
        Circle()
            .fill(isYou ? Color.appPine : PersonPalette.color(for: id))
            .frame(width: size, height: size)
            .overlay(
                Text(isYou ? "you".localizeString() : personInitials(name))
                    .font(.system(size: size * 0.36, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1).minimumScaleFactor(0.5)
            )
    }
}

// MARK: - Flow layout (wrapping chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                y += rowHeight + spacing
                x = 0; rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        let width = (maxWidth == .infinity) ? x : maxWidth
        return CGSize(width: width, height: y + rowHeight)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Segmented type picker

struct SegmentedTypePicker: View {
    @Binding var selection: TransactionType
    var body: some View {
        HStack(spacing: 2) {
            segment(.expense)
            segment(.income)
            segment(.saving)
        }
        .padding(4)
        .background(Color.appChipBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    private func segment(_ type: TransactionType) -> some View {
        let selected = selection == type
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { selection = type }
        } label: {
            Text(type.description())
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(selected ? .appInk : .appMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(selected ? Color.appCard : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 11))
                .shadow(color: selected ? .black.opacity(0.06) : .clear, radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Editable split-breakdown row

struct SplitAmountRow: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var errorHandling: ErrorHandling

    @Binding var participant: Participant
    @Binding var splitOption: SplitOption
    @Binding var participants: [Participant]
    @Binding var totalAmount: Double
    @Binding var hasWritten: [String]
    var action: TransactionAction

    @State private var amountString: String = ""
    @State private var amountSelected: Bool = false
    @FocusState private var isInputActive: Bool

    private var isYou: Bool { participant.userId == userViewModel.user.id }
    private var editable: Bool {
        action != .view && splitOption != .meEverything && splitOption != .heSheEverything
    }

    var body: some View {
        HStack(spacing: 9) {
            PersonAvatar(name: participant.userName, id: participant.userId, isYou: isYou, size: 26)
            Text(isYou ? "you".localizeString() : participant.userName.split(separator: " ").first.map(String.init) ?? participant.userName)
                .font(.system(size: 14, weight: .medium)).foregroundColor(.appInk)
            Spacer()
            if editable {
                HStack(spacing: 3) {
                    TextField("0", text: $amountString, onEditingChanged: { isEditing in
                        amountSelected = isEditing
                        if !isEditing {
                            let expression = amountString
                                .components(separatedBy: .whitespaces).joined()
                                .replacingOccurrences(of: ",", with: ".")
                                .replacingOccurrences(of: "÷", with: "/")
                                .replacingOccurrences(of: "×", with: "*")
                            if let doubleAmount = try? expression.evaluate() {
                                DispatchQueue.main.async {
                                    participant.amount = Utility.doubleToTwoDecimals(value: doubleAmount)
                                    if let errorString = Utility.setAmountPerParticipant(splitOption: splitOption, participants: $participants, totalAmount: totalAmount, hasWritten: hasWritten, myUserId: userViewModel.user.id) {
                                        errorHandling.handle(error: ApplicationError.unexpectedNil(errorString))
                                    }
                                }
                            }
                        }
                    })
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.mono(14))
                    .fixedSize()
                    .focused($isInputActive)
                    .toolbar {
                        if amountSelected {
                            ToolbarItemGroup(placement: .keyboard) {
                                CalculatorToolbarView(amountString: $amountString)
                                Spacer()
                                Button("done".localizeString()) { isInputActive = false }
                            }
                        }
                    }
                    Text(Utility.currencyFormatter.currencySymbol)
                        .font(.mono(14)).foregroundColor(.appMuted)
                }
                .foregroundColor(.appInk)
            } else {
                Text(Utility.doubleToLocalCurrency(value: participant.amount))
                    .font(.mono(14)).foregroundColor(.appMuted)
            }
        }
        .padding(.vertical, 9)
        .onChange(of: amountString) { _ in
            DispatchQueue.main.async {
                if amountSelected && !hasWritten.contains(participant.userId) {
                    hasWritten.append(participant.userId)
                }
            }
        }
        .onChange(of: participant.amount) { newValue in
            DispatchQueue.main.async {
                amountString = Utility.currencyFormatterNoSymbolNoZeroSymbol.string(from: newValue as NSNumber) ?? "0"
            }
        }
        .onAppear {
            amountString = Utility.currencyFormatterNoSymbolNoZeroSymbol.string(from: participant.amount as NSNumber) ?? "0"
        }
    }
}

// MARK: - Friend picker bottom sheet

struct FriendPickerSheet: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var errorHandling: ErrorHandling
    @Environment(\.dismiss) private var dismiss

    @Binding var participants: [Participant]
    @State private var query: String = ""
    @State private var expandedGroups: Set<String> = []

    private let collapseLimit = 6

    private var selectedIds: Set<String> {
        Set(participants.map { $0.userId }).subtracting([userViewModel.user.id])
    }

    private func matches(_ f: any Named) -> Bool {
        query.isEmpty || f.name.lowercased().contains(query.lowercased())
    }

    private func toggle(_ f: any Named) {
        if participants.contains(where: { $0.userId == f.id }) {
            participants.removeAll { $0.userId == f.id }
        } else {
            participants.append(Participant(userId: f.id, userName: f.name))
        }
    }

    private var favourites: [any Named] { userViewModel.getFavouritesSorted() }

    private var groups: [(name: String, members: [any Named])] {
        userViewModel.getFriendGroupsSorted().map { group in
            let members: [any Named] = userViewModel.getFriendsSorted().filter { userViewModel.getFriendGroup(friendId: $0.id) == group }
                + userViewModel.getCustomFriendsSorted().filter { $0.group == group }
            return (group.isEmpty ? "noGroup".localizeString() : group, members)
        }.filter { !$0.members.isEmpty }
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.appTrack).frame(width: 38, height: 5).padding(.top, 10).padding(.bottom, 4)

            HStack {
                Text("chooseFriends".localizeString()).font(.system(size: 17, weight: .bold)).foregroundColor(.appInk)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text(selectedIds.isEmpty ? "done".localizeString() : "\("done".localizeString()) · \(selectedIds.count)")
                        .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Color.appPine).clipShape(RoundedRectangle(cornerRadius: 11))
                }
            }
            .padding(.horizontal, 18).padding(.bottom, 12)

            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass").foregroundColor(.appMuted)
                TextField("searchFriendOrGroup".localizeString(), text: $query)
                    .foregroundColor(.appInk).autocorrectionDisabled()
            }
            .padding(.horizontal, 13).padding(.vertical, 11)
            .background(Color.appCard2)
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.appLine))
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .padding(.horizontal, 18).padding(.bottom, 8)

            if !selectedIds.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(participants.filter { $0.userId != userViewModel.user.id }, id: \.userId) { p in
                            Button {
                                participants.removeAll { $0.userId == p.userId }
                            } label: {
                                HStack(spacing: 6) {
                                    PersonAvatar(name: p.userName, id: p.userId, size: 22)
                                    Text(p.userName.split(separator: " ").first.map(String.init) ?? p.userName)
                                        .font(.system(size: 13, weight: .semibold))
                                    Image(systemName: "xmark").font(.system(size: 9, weight: .bold)).opacity(0.7)
                                }
                                .foregroundColor(.appPineInk)
                                .padding(.leading, 5).padding(.trailing, 8).padding(.vertical, 5)
                                .background(Color.appPineSoft).clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 18).padding(.bottom, 12)
                }
                Divider().overlay(Color.appLine)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    let favs = favourites.filter(matches)
                    if !favs.isEmpty {
                        groupHeader("favourites".localizeString(), addAll: nil)
                        ForEach(favs, id: \.id) { friendRow($0) }
                    }

                    ForEach(groups, id: \.name) { group in
                        let visible = group.members.filter(matches)
                        if !visible.isEmpty {
                            let searching = !query.isEmpty
                            let expanded = searching || expandedGroups.contains(group.name)
                            let shown = expanded ? visible : Array(visible.prefix(collapseLimit))
                            groupHeader(group.name, addAll: searching ? nil : groupActionLabel(group: group, visibleCount: visible.count, expanded: expanded)) {
                                let ids = group.members.map { $0.id }
                                let allIn = ids.allSatisfy { selectedIds.contains($0) }
                                if allIn {
                                    participants.removeAll { p in ids.contains(p.userId) }
                                } else {
                                    for m in group.members where !participants.contains(where: { $0.userId == m.id }) {
                                        participants.append(Participant(userId: m.id, userName: m.name))
                                    }
                                    expandedGroups.insert(group.name)
                                }
                            }
                            ForEach(shown, id: \.id) { friendRow($0) }
                            if !expanded && visible.count > collapseLimit {
                                Button { expandedGroups.insert(group.name) } label: {
                                    Text(String(format: "showAllCount".localizeString(), visible.count))
                                        .font(.system(size: 13, weight: .semibold)).foregroundColor(.appPine)
                                        .padding(.vertical, 8).padding(.leading, 4)
                                }.buttonStyle(.plain)
                            }
                        }
                    }

                    if favs.isEmpty && groups.allSatisfy({ $0.members.filter(matches).isEmpty }) {
                        Text("noMatches".localizeString())
                            .font(.system(size: 14)).foregroundColor(.appMuted)
                            .frame(maxWidth: .infinity).padding(.top, 30)
                    }
                }
                .padding(.horizontal, 18).padding(.bottom, 24)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
    }

    private func groupActionLabel(group: (name: String, members: [any Named]), visibleCount: Int, expanded: Bool) -> String {
        let ids = group.members.map { $0.id }
        let allIn = ids.allSatisfy { selectedIds.contains($0) }
        if allIn { return "removeAll".localizeString() }
        return expanded ? "addAll".localizeString() : String(format: "showAllCount".localizeString(), visibleCount)
    }

    @ViewBuilder
    private func groupHeader(_ title: String, addAll: String?, action: (() -> Void)? = nil) -> some View {
        HStack {
            Text(title.uppercased()).font(.system(size: 12, weight: .bold)).kerning(0.8).foregroundColor(.appMuted)
            Spacer()
            if let addAll, let action {
                Button(action: action) {
                    Text(addAll).font(.system(size: 13, weight: .semibold)).foregroundColor(.appPine)
                }.buttonStyle(.plain)
            }
        }
        .padding(.top, 16).padding(.bottom, 6)
    }

    private func friendRow(_ f: any Named) -> some View {
        let selected = selectedIds.contains(f.id)
        return Button { toggle(f) } label: {
            HStack(spacing: 12) {
                PersonAvatar(name: f.name, id: f.id, size: 38)
                Text(f.name).font(.system(size: 15.5, weight: .medium)).foregroundColor(.appInk)
                Spacer()
                ZStack {
                    Circle()
                        .fill(selected ? Color.appPine : Color.clear)
                        .frame(width: 24, height: 24)
                        .overlay(Circle().stroke(selected ? Color.appPine : Color.appLine, lineWidth: 2))
                    if selected {
                        Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                    }
                }
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}
