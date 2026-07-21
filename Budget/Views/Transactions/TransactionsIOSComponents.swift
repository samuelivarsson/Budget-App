//
//  TransactionsIOSComponents.swift
//  Budget
//
//  iOS 26 styled building blocks for the Transactions screen (v2).
//  Solid fills / system colors only — no backdrop-blur materials (scroll perf).
//

import SwiftUI

extension View {
    /// Solid rounded "card" surface (no material, no shadow) for smooth scrolling.
    func iosCard(_ radius: CGFloat = 22) -> some View {
        self
            .background(Color.iosCardFill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(Color.primary.opacity(0.06), lineWidth: 1))
    }
}

// MARK: - Filter

enum TxFilter: CaseIterable {
    case all, expense, income, transfer
    var title: String {
        switch self {
        case .all: return "all"
        case .expense: return "expense"   // TransactionType names
        case .income: return "income"
        case .transfer: return "saving"
        }
    }
    var dot: Color? {
        switch self {
        case .all: return nil
        case .expense: return Color(red: 1.0, green: 0.36, blue: 0.32)
        case .income: return Color(red: 0.18, green: 0.82, blue: 0.35)
        case .transfer: return Color(red: 0.22, green: 0.82, blue: 0.88)
        }
    }
    func matches(_ type: TransactionType) -> Bool {
        switch self {
        case .all: return true
        case .expense: return type == .expense
        case .income: return type == .income
        case .transfer: return type == .saving
        }
    }
}

struct IOSFilterBar: View {
    @Binding var selection: TxFilter
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TxFilter.allCases, id: \.self) { f in
                    let active = selection == f
                    Button { selection = f } label: {
                        HStack(spacing: 6) {
                            if let dot = f.dot { Circle().fill(dot).frame(width: 7, height: 7) }
                            Text(LocalizedStringKey(f.title)).font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(active ? Color.iosBG : .secondary)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(active ? Color.primary : Color.iosCardFill)
                        .overlay(Capsule().strokeBorder(Color.primary.opacity(active ? 0 : 0.06), lineWidth: 1))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

// MARK: - Transaction avatar

struct TxAvatar: View {
    @AppStorage("transactionIconFilled") private var filled: Bool = false
    let letter: String
    let type: TransactionType
    private var visual: (symbol: String, colors: [Color]) {
        switch type {
        case .expense: return ("arrow.down", [Color(red: 1.0, green: 0.36, blue: 0.32), Color(red: 1.0, green: 0.54, blue: 0.36)])
        case .income:  return ("arrow.up", [Color(red: 0.18, green: 0.71, blue: 0.42), Color(red: 0.20, green: 0.78, blue: 0.35)])
        case .saving:  return ("arrow.left.arrow.right", [Color(red: 0.06, green: 0.71, blue: 0.79), Color(red: 0.22, green: 0.82, blue: 0.88)])
        }
    }
    var body: some View {
        if filled {
            // Type icon fills the whole gradient tile.
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(colors: visual.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: visual.symbol).font(.system(size: 20, weight: .bold)).foregroundColor(.white))
        } else {
            // Letter with a small type badge in the corner.
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.primary.opacity(0.06))
                    .frame(width: 44, height: 44)
                    .overlay(Text(letter).font(.system(size: 19, weight: .bold)).foregroundColor(.secondary))
                Image(systemName: visual.symbol)
                    .font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                    .frame(width: 18, height: 18)
                    .background(LinearGradient(colors: visual.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Color.iosBG, lineWidth: 2))
                    .offset(x: 4, y: 4)
            }
        }
    }
}

// MARK: - Transaction card

struct IOSTxCard: View {
    let transaction: Transaction
    let userId: String
    var editing: Bool = false
    var onDelete: (() -> Void)? = nil

    /// Shown as the row title and used for the avatar letter — falls back to the
    /// category name when there's no description (common on others' transactions).
    private var title: String {
        transaction.desc.isEmpty ? transaction.category.name : transaction.desc
    }
    private var isSplit: Bool { transaction.participants.count > 1 }
    private var iPaid: Bool { transaction.payerId == userId }
    private var myShare: Double { transaction.getShare(userId: userId) }
    private func money(_ v: Double) -> String { Utility.doubleToLocalCurrency(value: v) }
    private var payerFirstName: String { String(transaction.payerName.split(separator: " ").first ?? "") }

    private var transfer: Color { Color(red: 0.06, green: 0.71, blue: 0.79) }
    private var amountColor: Color {
        switch transaction.type {
        case .income: return .green
        case .saving: return transfer
        case .expense: return .primary
        }
    }
    private var dotColor: Color {
        switch transaction.type {
        case .income: return .green
        case .saving: return transfer
        case .expense: return Color.forCategory(transaction.category.name)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            if editing {
                Button { onDelete?() } label: {
                    Image(systemName: "minus.circle.fill").font(.system(size: 20)).foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            TxAvatar(letter: String(title.prefix(1)).uppercased(), type: transaction.type)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15.5, weight: .semibold)).foregroundColor(.primary).lineLimit(1)
                HStack(spacing: 6) {
                    Circle().fill(dotColor).frame(width: 7, height: 7)
                    Text(transaction.category.name).font(.system(size: 12.5)).foregroundColor(.secondary).lineLimit(1)
                }
                if isSplit {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill").font(.system(size: 9))
                        Text(sharedText).font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 8).padding(.vertical, 2.5)
                    .background(Color.accentColor.opacity(0.12)).clipShape(Capsule())
                    .padding(.top, 3)
                }
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 3) {
                Text((transaction.type == .income ? "+" : "") + money(myShare))
                    .font(.system(size: 15.5, weight: .bold)).foregroundColor(amountColor).monospacedDigit()
                if isSplit {
                    Text("\("of".localizeString()) \(money(transaction.totalAmount))")
                        .font(.system(size: 12)).foregroundColor(.secondary).monospacedDigit()
                }
                payChip
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 13)
        .iosCard(22)
    }

    private var sharedText: String {
        let friends = transaction.participants.count - 1
        let word = (friends > 1 ? "friends" : "friend").localizeString().lowercased()
        return "\("you".localizeString()) \("and".localizeString().lowercased()) \(friends) \(word)"
    }

    private var payChip: some View {
        let text = iPaid ? "youPaid".localizeString() : String(format: "personPaid".localizeString(), payerFirstName)
        return Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(iPaid ? .secondary : transfer)
            .padding(.horizontal, 8).padding(.vertical, 2.5)
            .background(iPaid ? Color.primary.opacity(0.08) : transfer.opacity(0.14))
            .clipShape(Capsule())
    }
}

// MARK: - Period head & collapsed period

struct IOSPeriodHead: View {
    let range: String
    let count: Int
    let isOpen: Bool
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 15, weight: .semibold)).foregroundColor(.secondary)
                    .rotationEffect(.degrees(isOpen ? 0 : -90))
                Text(range).font(.system(size: 16, weight: .bold)).foregroundColor(.primary)
                Spacer()
                Text(String(format: "transactionsCount".localizeString(), count))
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(.secondary).monospacedDigit()
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6).padding(.top, 16).padding(.bottom, 10)
    }
}

struct IOSCollapsedPeriod: View {
    let range: String
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.right").font(.system(size: 15, weight: .semibold)).foregroundColor(.secondary)
                Text(range).font(.system(size: 16, weight: .semibold)).foregroundColor(.secondary)
                Spacer()
                Text("show").font(.system(size: 13, weight: .semibold)).foregroundColor(.accentColor)
            }
            .padding(16)
            .iosCard(22)
        }
        .buttonStyle(.plain)
    }
}
