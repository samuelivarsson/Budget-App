import SwiftUI

// MARK: - Logic

enum DayRelativity { case today, yesterday, other }

func dayRelativity(_ date: Date, now: Date, calendar: Calendar = .current) -> DayRelativity {
    if calendar.isDate(date, inSameDayAs: now) { return .today }
    if let y = calendar.date(byAdding: .day, value: -1, to: now),
       calendar.isDate(date, inSameDayAs: y) { return .yesterday }
    return .other
}

func groupTransactionsByDay(_ transactions: [Transaction],
                            calendar: Calendar = .current) -> [(day: Date, items: [Transaction])] {
    let grouped = Dictionary(grouping: transactions) { calendar.startOfDay(for: $0.date) }
    return grouped.keys.sorted(by: >).map { key in
        (day: key, items: grouped[key]!.sorted { $0.date > $1.date })
    }
}

func sumMyShare(_ transactions: [Transaction], userId: String) -> Double {
    transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.getShare(userId: userId) }
}

// MARK: - Views

struct Avatar: View {
    let letter: String
    let type: TransactionType
    private var badge: (String, Color) {
        switch type {
        case .expense: return ("arrow.down", .appRed)
        case .income:  return ("arrow.up", .appPine)
        case .saving:  return ("arrow.left.arrow.right", .appInfo)
        }
    }
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 13).fill(Color.appChipBg)
                .frame(width: 40, height: 40)
                .overlay(Text(letter).font(.system(size: 16, weight: .bold)).foregroundColor(.appInk))
            Image(systemName: badge.0)
                .font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                .frame(width: 19, height: 19).background(badge.1).clipShape(Circle())
                .overlay(Circle().stroke(Color.appCard, lineWidth: 2.5))
                .offset(x: 4, y: 4)
        }
    }
}

struct TransactionCard: View {
    let transaction: Transaction
    let userId: String

    private var isSplit: Bool { transaction.participants.count > 1 }
    private var iPaid: Bool { transaction.payerId == userId }
    private var myShare: Double { transaction.getShare(userId: userId) }
    private var sharePercent: Double {
        transaction.totalAmount == 0 ? 0 : myShare / transaction.totalAmount * 100
    }
    private var amountColor: Color {
        switch transaction.type { case .income: return .appPine; case .saving: return .appInfo; case .expense: return .appInk }
    }
    private func money(_ v: Double) -> String { Utility.doubleToLocalCurrency(value: v) }
    private var payerFirstName: String { String(transaction.payerName.split(separator: " ").first ?? "") }

    var body: some View {
        AppCard(padding: 0) {
            VStack(spacing: 0) {
                HStack(spacing: 13) {
                    Avatar(letter: String(transaction.desc.prefix(1)).uppercased(),
                           type: transaction.type)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(transaction.desc.isEmpty ? transaction.category.name : transaction.desc)
                            .font(.system(size: 15.5, weight: .semibold)).foregroundColor(.appInk)
                            .lineLimit(1)
                        HStack(spacing: 5) {
                            Circle().fill(Color.forCategory(transaction.category.name)).frame(width: 7, height: 7)
                            Text(transaction.category.name).font(.system(size: 12)).foregroundColor(.appMuted)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text((transaction.type == .income ? "+ " : "") + money(myShare))
                            .font(.mono(16)).foregroundColor(amountColor)
                        if isSplit {
                            Text("of".localizeString() + " " + money(transaction.totalAmount))
                                .font(.mono(12, weight: .regular)).foregroundColor(.appMuted)
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 14)

                if isSplit {
                    VStack(spacing: 8) {
                        SplitBar(percent: sharePercent)
                        HStack {
                            Text(String(format: "yourSharePercent".localizeString(), Int(sharePercent.rounded())))
                                .font(.system(size: 12)).foregroundColor(.appMuted)
                            Spacer()
                            let text = iPaid ? "youPaid".localizeString()
                                             : String(format: "personPaid".localizeString(), payerFirstName)
                            Text(text)
                                .font(.system(size: 11.5, weight: .semibold))
                                .padding(.horizontal, 9).padding(.vertical, 3)
                                .foregroundColor(iPaid ? .appPineInk : .appAmber)
                                .background(iPaid ? Color.appPineSoft : Color.appAmberSoft)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.leading, 69).padding(.trailing, 16).padding(.bottom, 13)
                }
            }
        }
    }
}

struct PeriodSelector: View {
    let range: String
    let count: String?
    let isOpen: Bool
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Text(range).font(.system(size: 15, weight: .semibold)).foregroundColor(.appInk)
                Spacer()
                if let count { Text(count).font(.mono(12, weight: .regular)).foregroundColor(.appMuted) }
            }
            .padding(.horizontal, 15).padding(.vertical, 13)
            .background(Color.appCard)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(isOpen ? Color.appPine.opacity(0.5) : Color.appLine))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }.buttonStyle(.plain)
    }
}

struct PeriodSummary: View {
    let shareLabel: String
    let shareValue: Double
    let oweLabel: String
    let oweValue: Double
    var body: some View {
        HStack(spacing: 10) {
            tile(shareLabel, shareValue)
            tile(oweLabel, oweValue)
        }
    }
    private func tile(_ k: String, _ v: Double) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(k).font(.system(size: 11)).foregroundColor(.appMuted)
            Text(Utility.doubleToLocalCurrency(value: v)).font(.mono(16)).foregroundColor(.appInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 13).padding(.vertical, 11)
        .background(Color.appCard2)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appLine))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 12) {
            PeriodSelector(range: "25 jun – 25 jul 2026", count: "8 st", isOpen: true, onTap: {})
            PeriodSummary(shareLabel: "Din del", shareValue: 1716,
                          oweLabel: "Du är skyldig", oweValue: 1482)
            TransactionCard(
                transaction: Transaction(totalAmount: 2833,
                    category: TransactionCategory(name: "Sparkonto köp", type: .expense),
                    date: Date(), desc: "Hotell Oskarshamn", creatorId: "me", creatorName: "Me",
                    payerId: "f", payerName: "Yasmine A",
                    participants: [Participant(amount: 1417, userId: "me", userName: "Me"),
                                   Participant(amount: 1416, userId: "f", userName: "Yasmine")],
                    type: .expense),
                userId: "me")
        }.padding()
    }.background(Color.appBackground)
}
