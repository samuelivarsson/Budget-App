//
//  AddTransactionIOSComponents.swift
//  Budget
//
//  iOS 26 styled pieces for the add/edit transaction screen (v2).
//  Solid fills / system colors — no backdrop-blur materials.
//

import SwiftUI
import MathParser

// MARK: - Person avatar (iOS)

struct IOSPersonAvatar: View {
    let name: String
    let id: String
    var isYou: Bool = false
    var size: CGFloat = 44
    private var youColors: [Color] { [Color(red: 0.04, green: 0.52, blue: 1.0), Color(red: 0.29, green: 0.66, blue: 1.0)] }
    var body: some View {
        Circle()
            .fill(isYou
                  ? AnyShapeStyle(LinearGradient(colors: youColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                  : AnyShapeStyle(PersonPalette.color(for: id)))
            .frame(width: size, height: size)
            .overlay(
                Text(isYou ? "you".localizeString() : personInitials(name))
                    .font(.system(size: size * 0.34, weight: .bold)).foregroundColor(.white)
                    .lineLimit(1).minimumScaleFactor(0.5)
            )
    }
}

// MARK: - Type segmented control

struct IOSTypeSegment: View {
    @Binding var selection: TransactionType
    private func color(_ t: TransactionType) -> Color {
        switch t {
        case .expense: return Color(red: 1.0, green: 0.36, blue: 0.32)
        case .income:  return .green
        case .saving:  return Color(red: 0.22, green: 0.82, blue: 0.88)
        }
    }
    var body: some View {
        HStack(spacing: 2) {
            ForEach(TransactionType.allCases, id: \.self) { t in
                let active = selection == t
                Button { withAnimation(.easeInOut(duration: 0.15)) { selection = t } } label: {
                    HStack(spacing: 6) {
                        Circle().fill(color(t)).frame(width: 8, height: 8)
                        Text(t.description()).font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(active ? color(t) : .secondary)
                    .frame(maxWidth: .infinity).frame(height: 38)
                    .background(active ? color(t).opacity(0.15) : Color.clear)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.iosCardFill, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.iosBorder, lineWidth: 1))
    }
}

// Shared focus identity so amount / description / per-participant fields can be
// focused across TransactionView and IOSShareRow (enables prev/next navigation).
enum AddTxField: Hashable {
    case amount
    case description
    case share(String)   // participant userId
    case own(String)     // participant userId
}

// MARK: - Editable per-participant share row

struct IOSShareRow: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var errorHandling: ErrorHandling

    @Binding var participant: Participant
    @Binding var splitOption: SplitOption
    @Binding var participants: [Participant]
    @Binding var totalAmount: Double
    @Binding var hasWritten: [String]
    var action: TransactionAction
    var showsTopDivider: Bool = true
    var focus: FocusState<AddTxField?>.Binding
    var order: [AddTxField]
    var onMove: (Int) -> Void

    @State private var amountString: String = ""
    @State private var ownString: String = ""
    @State private var amountSelected: Bool = false
    @State private var ownSelected: Bool = false

    private var shareFieldId: AddTxField { .share(participant.userId) }
    private var ownFieldId: AddTxField { .own(participant.userId) }

    private var isYou: Bool { participant.userId == userViewModel.user.id }
    private var isOwnItems: Bool { splitOption == .ownItems }
    private var totalEditable: Bool {
        action != .view && splitOption != .meEverything && splitOption != .heSheEverything && !isOwnItems
    }
    private var name: String {
        isYou ? "you".localizeString() : (participant.userName.split(separator: " ").first.map(String.init) ?? participant.userName)
    }
    private func fmt(_ v: Double) -> String { Utility.currencyFormatterNoSymbolNoZeroSymbol.string(from: v as NSNumber) ?? "0" }

    private var ownAmount: Double { participant.ownAmount ?? 0 }
    private var sharedAmount: Double { participant.amount - ownAmount }
    private var subline: String {
        let shared = "\(fmt(sharedAmount)) \("splitShared".localizeString())"
        return ownAmount > 0 ? "\(shared) + \(fmt(ownAmount)) \("splitOwn".localizeString())" : shared
    }

    var body: some View {
        VStack(spacing: 0) {
            if showsTopDivider { Divider().overlay(Color.iosBorder) }
            HStack(spacing: 10) {
                IOSPersonAvatar(name: participant.userName, id: participant.userId, isYou: isYou, size: 30)
                VStack(alignment: .leading, spacing: 1) {
                    Text(name).font(.system(size: 14.5, weight: .semibold)).foregroundColor(.primary)
                    if isOwnItems {
                        Text(subline).font(.system(size: 11)).foregroundColor(.secondary).monospacedDigit()
                    }
                }
                Spacer(minLength: 6)
                if isOwnItems {
                    if action != .view { ownField }
                    totalChip
                } else if totalEditable {
                    totalField
                } else {
                    totalChip
                }
            }
            .padding(.vertical, 11)
        }
        .onChange(of: amountString) { _ in
            DispatchQueue.main.async {
                if amountSelected && !hasWritten.contains(participant.userId) { hasWritten.append(participant.userId) }
            }
        }
        .onChange(of: participant.amount) { newValue in
            DispatchQueue.main.async { amountString = fmt(newValue) }
        }
        .onChange(of: participant.ownAmount) { _ in
            // Re-sync the field after a commit so an entered expression (e.g. 100+50)
            // is shown as its evaluated value, and isn't overwritten while editing.
            guard !ownSelected else { return }
            DispatchQueue.main.async { ownString = fmt(ownAmount) }
        }
        .onAppear {
            amountString = fmt(participant.amount)
            ownString = fmt(ownAmount)
        }
    }

    @ViewBuilder
    private func chevrons(_ field: AddTxField) -> some View {
        let idx = order.firstIndex(of: field) ?? 0
        Button { onMove(-1) } label: { Image(systemName: "chevron.up") }.disabled(idx <= 0)
        Button { onMove(1) } label: { Image(systemName: "chevron.down") }.disabled(idx >= order.count - 1)
    }

    // Read-only amount (auto-computed splits, or when this participant's amount
    // isn't editable for the chosen Fördelning). Plain text — no input pill — so
    // it's clearly not tappable, unlike the editable pill/dashed fields.
    private var totalChip: some View {
        Text(Utility.doubleToLocalCurrency(value: participant.amount))
            .font(.system(size: 14.5, weight: .bold)).monospacedDigit().foregroundColor(.secondary)
            .padding(.vertical, 5)
    }

    private var totalField: some View {
        HStack(spacing: 3) {
            TextField("0", text: $amountString, onEditingChanged: { editing in
                amountSelected = editing
                if !editing { commit(amountString) { participant.amount = $0 } }
            })
            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
            .font(.system(size: 14.5, weight: .bold)).monospacedDigit().fixedSize()
            .focused(focus, equals: shareFieldId)
            .toolbar {
                if focus.wrappedValue == shareFieldId {
                    ToolbarItemGroup(placement: .keyboard) {
                        CalculatorToolbarView(amountString: $amountString)
                        Spacer()
                        chevrons(shareFieldId)
                        Button("done".localizeString()) { focus.wrappedValue = nil }
                    }
                }
            }
            Text(Utility.currencyFormatter.currencySymbol).font(.system(size: 14.5, weight: .bold)).foregroundColor(.secondary)
        }
        .foregroundColor(.primary)
        .padding(.horizontal, 12).padding(.vertical, 5)
        .background(Color.primary.opacity(0.06), in: Capsule())
        .contentShape(Capsule())
        .onTapGesture { focus.wrappedValue = shareFieldId }
    }

    private var ownField: some View {
        HStack(spacing: 4) {
            Text("ownLabel").font(.system(size: 12.5, weight: .semibold)).foregroundColor(.secondary)
                .lineLimit(1).fixedSize()
            TextField("0", text: $ownString, onEditingChanged: { editing in
                ownSelected = editing
                if !editing {
                    // Own amounts can't exceed what's left of the total after the
                    // other participants' own amounts (so alone or combined ≤ total).
                    let othersOwn = participants
                        .filter { $0.userId != participant.userId }
                        .reduce(0.0) { $0 + ($1.ownAmount ?? 0) }
                    let cap = Swift.max(0, totalAmount - othersOwn)
                    commit(ownString, cap: cap) { participant.ownAmount = $0 }
                }
            })
            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
            .font(.system(size: 12.5, weight: .semibold)).monospacedDigit().fixedSize()
            .focused(focus, equals: ownFieldId)
            .toolbar {
                if focus.wrappedValue == ownFieldId {
                    ToolbarItemGroup(placement: .keyboard) {
                        CalculatorToolbarView(amountString: $ownString)
                        Spacer()
                        chevrons(ownFieldId)
                        Button("done".localizeString()) { focus.wrappedValue = nil }
                    }
                }
            }
        }
        .foregroundColor(.primary)
        .padding(.horizontal, 11).padding(.vertical, 5)
        .overlay(
            Capsule().strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                .foregroundColor(Color.primary.opacity(0.28))
                .allowsHitTesting(false)   // don't steal taps from the text field
        )
        .contentShape(Capsule())
        .onTapGesture { focus.wrappedValue = ownFieldId }
    }

    private func commit(_ string: String, cap: Double? = nil, _ assign: @escaping (Double) -> Void) {
        let expression = string
            .components(separatedBy: .whitespaces).joined()
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: "÷", with: "/")
            .replacingOccurrences(of: "×", with: "*")
        if let value = try? expression.evaluate() {
            DispatchQueue.main.async {
                var amount = Utility.doubleToTwoDecimals(value: value)
                if let cap = cap { amount = Swift.min(Swift.max(amount, 0), cap) }
                assign(amount)
                if let errorString = Utility.setAmountPerParticipant(splitOption: splitOption, participants: $participants, totalAmount: totalAmount, hasWritten: hasWritten, myUserId: userViewModel.user.id) {
                    errorHandling.handle(error: ApplicationError.unexpectedNil(errorString))
                }
            }
        }
    }
}

// MARK: - Friend picker sheet (iOS)

struct IOSFriendSheet: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @Environment(\.dismiss) private var dismiss

    @Binding var participants: [Participant]
    @State private var query: String = ""
    @State private var expandedGroups: Set<String> = []
    private let collapseLimit = 4

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
            // Custom grabber (system indicator hidden) for controlled spacing
            Capsule()
                .fill(Color.primary.opacity(0.22))
                .frame(width: 36, height: 5)
                .padding(.top, 10).padding(.bottom, 18)

            // Fixed header
            HStack {
                Text("allFriends").font(.system(size: 20, weight: .bold)).foregroundColor(.primary)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundColor(.secondary)
                        .frame(width: 32, height: 32).background(Color.primary.opacity(0.08)).clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18).padding(.bottom, 12)

            // Fixed search
            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("searchFriendOrGroup".localizeString(), text: $query).autocorrectionDisabled()
            }
            .padding(.horizontal, 14).frame(height: 44)
            .background(Color.primary.opacity(0.06), in: Capsule())
            .padding(.horizontal, 18)

            // Fixed selected chips
            if !selectedIds.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(participants.filter { $0.userId != userViewModel.user.id }, id: \.userId) { p in
                            Button { participants.removeAll { $0.userId == p.userId } } label: {
                                HStack(spacing: 6) {
                                    IOSPersonAvatar(name: p.userName, id: p.userId, size: 22)
                                    Text(p.userName.split(separator: " ").first.map(String.init) ?? p.userName)
                                        .font(.system(size: 13, weight: .semibold))
                                    Image(systemName: "xmark").font(.system(size: 9, weight: .bold))
                                }
                                .foregroundColor(.accentColor)
                                .padding(.leading, 5).padding(.trailing, 8).padding(.vertical, 5)
                                .background(Color.accentColor.opacity(0.12)).clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 18).padding(.vertical, 10)
                }
            }

            // Scrolling list
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    let favs = favourites.filter(matches)
                    if !favs.isEmpty {
                        groupHeader("favourites".localizeString(), members: favourites)
                        friendListCard(shown: favs, showMore: false, moreCount: 0, groupName: "")
                    }
                    ForEach(groups, id: \.name) { group in
                        let visible = group.members.filter(matches)
                        if !visible.isEmpty {
                            let expanded = !query.isEmpty || expandedGroups.contains(group.name)
                            let shown = expanded ? visible : Array(visible.prefix(collapseLimit))
                            groupHeader("\(group.name) · \(group.members.count) \(("friends").localizeString().lowercased())", members: group.members)
                            friendListCard(shown: shown,
                                           showMore: !expanded && visible.count > collapseLimit,
                                           moreCount: visible.count - collapseLimit,
                                           groupName: group.name)
                        }
                    }
                }
                .padding(.horizontal, 18).padding(.top, 2).padding(.bottom, 24)
            }
        }
        .background(Color.iosBG.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            Button { dismiss() } label: {
                Text(selectedIds.isEmpty ? "done".localizeString() : "\("done".localizeString()) · \(String(format: "selectedCount".localizeString(), selectedIds.count))")
                    .font(.system(size: 16.5, weight: .bold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(Color.accentColor).clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 6)
            .background(Color.iosBG)
        }
        .presentationDetents([.fraction(0.92)])
        .presentationDragIndicator(.hidden)
    }

    @ViewBuilder
    private func friendListCard(shown: [any Named], showMore: Bool, moreCount: Int, groupName: String) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(shown.enumerated()), id: \.element.id) { i, f in
                if i > 0 { Divider().overlay(Color.iosBorder).padding(.leading, 50) }
                friendRow(f)
            }
            if showMore {
                Divider().overlay(Color.iosBorder).padding(.leading, 50)
                Button { expandedGroups.insert(groupName) } label: {
                    HStack(spacing: 6) {
                        Text(String(format: "showMoreCount".localizeString(), moreCount))
                        Image(systemName: "chevron.down")
                    }
                    .font(.system(size: 13.5, weight: .semibold)).foregroundColor(.accentColor)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14).iosCard(22)
    }

    @ViewBuilder
    private func groupHeader(_ title: String, members: [any Named]) -> some View {
        HStack {
            Text(title).font(.system(size: 11, weight: .bold)).kerning(0.7).textCase(.uppercase).foregroundColor(.secondary)
            Spacer()
            Button {
                let ids = members.map { $0.id }
                let allIn = ids.allSatisfy { selectedIds.contains($0) }
                if allIn { participants.removeAll { p in ids.contains(p.userId) } }
                else { for m in members where !participants.contains(where: { $0.userId == m.id }) { participants.append(Participant(userId: m.id, userName: m.name)) } }
            } label: {
                let ids = members.map { $0.id }
                let allIn = ids.allSatisfy { selectedIds.contains($0) }
                HStack(spacing: 4) {
                    Image(systemName: allIn ? "minus" : "plus").font(.system(size: 10, weight: .bold))
                    Text(allIn ? "removeAll" : "addAll").font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.accentColor)
                .padding(.horizontal, 11).padding(.vertical, 5)
                .background(Color.accentColor.opacity(0.12)).clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 18).padding(.bottom, 8).padding(.horizontal, 4)
    }

    private func friendRow(_ f: any Named) -> some View {
        let selected = selectedIds.contains(f.id)
        return Button { toggle(f) } label: {
            HStack(spacing: 12) {
                IOSPersonAvatar(name: f.name, id: f.id, size: 38)
                Text(f.name).font(.system(size: 15.5, weight: .semibold)).foregroundColor(.primary)
                Spacer()
                ZStack {
                    Circle().fill(selected ? Color.accentColor : Color.clear).frame(width: 24, height: 24)
                        .overlay(Circle().strokeBorder(selected ? Color.accentColor : Color.primary.opacity(0.2), lineWidth: 2))
                    if selected { Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundColor(.white) }
                }
            }
            .padding(.vertical, 11)
        }
        .buttonStyle(.plain)
    }
}
