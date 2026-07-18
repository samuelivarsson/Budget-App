import SwiftUI

struct HomeSummary {
    let income: Double
    let spent: Double
    let ceiling: Double
    let withinTakCount: Int
    let totalCount: Int
    init(income: Double, rows: [(spent: Double, ceiling: Double)]) {
        self.income = income
        self.spent = rows.reduce(0) { $0 + $1.spent }
        self.ceiling = rows.reduce(0) { $0 + $1.ceiling }
        self.totalCount = rows.count
        self.withinTakCount = rows.filter { $0.spent <= $0.ceiling }.count
    }
    var remaining: Double { ceiling - spent }
    var progress: Double { ceiling <= 0 ? 0 : min(max(spent / ceiling, 0), 1) }
}

struct HeroCard: View {
    let label: String
    let summary: HomeSummary
    let incomeLabel: String
    let spentLabel: String
    let ceilingLabel: String

    private func money(_ v: Double) -> String { Utility.doubleToLocalCurrency(value: v) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label).font(.system(size: 13, weight: .semibold)).foregroundColor(.heroMuted)
            Text(money(summary.remaining))
                .font(.mono(30)).foregroundColor(.heroInk)
                .padding(.top, 4).padding(.bottom, 12)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.heroTrack)
                    Capsule().fill(Color.heroFill).frame(width: geo.size.width * summary.progress)
                }
            }.frame(height: 8).padding(.bottom, 12)
            HStack(spacing: 14) {
                stat(incomeLabel, summary.income)
                stat(spentLabel, summary.spent)
                stat(ceilingLabel, summary.ceiling)
            }
        }
        .padding(18)
        .background(LinearGradient(colors: [.heroTop, .heroBottom],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
    }

    private func stat(_ k: String, _ v: Double) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(k).font(.system(size: 11)).foregroundColor(.heroMuted)
            Text(money(v)).font(.mono(12)).foregroundColor(.heroInk).lineLimit(1).minimumScaleFactor(0.6)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AccountRow: View {
    let name: String
    let meta: String?
    let amount: Double
    let deviation: Double?   // quickBalance - balance, when non-zero
    let onTap: (() -> Void)?

    var body: some View {
        let row = AppCard {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(name).font(.system(size: 16, weight: .semibold)).foregroundColor(.appInk)
                    if let meta { Text(meta).font(.system(size: 12)).foregroundColor(.appMuted) }
                    if let deviation {
                        let sign = deviation >= 0 ? "+" : ""
                        Chip("Avviker \(sign)\(Utility.doubleToLocalCurrency(value: deviation))",
                             style: .deviation)
                    }
                }
                Spacer()
                Text(Utility.doubleToLocalCurrency(value: amount))
                    .font(.mono(17)).foregroundColor(.appInk)
            }
        }
        if let onTap {
            Button(action: onTap) { row }.buttonStyle(.plain)
        } else {
            row
        }
    }
}

/// Account row for quick-balance ("snabbsaldo") accounts. Uses @AppStorage so it
/// observes UserDefaults and re-renders + animates when a refresh completes.
struct HomeQuickBalanceRow: View {
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var quickBalanceViewModel: QuickBalanceViewModel

    @AppStorage private var quickBalance: Double
    @AppStorage private var lastUpdate: String
    @State private var animate = false

    let account: Account
    let balance: Double
    let quickBalanceAccount: QuickBalanceAccount
    let updatedLabel: String

    init(account: Account, balance: Double, quickBalanceAccount: QuickBalanceAccount, updatedLabel: String) {
        self.account = account
        self.balance = balance
        self.quickBalanceAccount = quickBalanceAccount
        self.updatedLabel = updatedLabel
        self._quickBalance = AppStorage(wrappedValue: 0, "QuickBalance:" + account.id,
                                        store: QuickBalanceViewModel.sharedUserDefaults)
        self._lastUpdate = AppStorage(wrappedValue: "-", "LastUpdate:" + account.id,
                                      store: QuickBalanceViewModel.sharedUserDefaults)
    }

    private var deviation: Double? {
        (round(quickBalance * 100) - round(balance * 100)) == 0 ? nil : (quickBalance - balance)
    }

    var body: some View {
        Button {
            quickBalanceViewModel.fetchQuickBalanceFromApi(quickBalanceAccount: quickBalanceAccount) { error in
                if let error = error { errorHandling.handle(error: error) }
            }
        } label: {
            AppCard {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(account.name).font(.system(size: 16, weight: .semibold)).foregroundColor(.appInk)
                        Text("\(updatedLabel) \(lastUpdate)")
                            .font(.system(size: 11)).foregroundColor(.appMuted)
                            .lineLimit(1).minimumScaleFactor(0.7)
                        if let deviation {
                            let sign = deviation >= 0 ? "+" : ""
                            Chip("Avviker \(sign)\(Utility.doubleToLocalCurrency(value: deviation))", style: .deviation)
                                .scaleEffect(animate ? 1.06 : 1)
                        }
                    }
                    Spacer(minLength: 8)
                    Text(Utility.doubleToLocalCurrency(value: balance))
                        .font(.mono(17)).foregroundColor(.appInk)
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .scaleEffect(animate ? 1.12 : 1)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(dampingFraction: 0.5), value: animate)
        .onChange(of: lastUpdate) { _ in
            animate = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { animate = false }
        }
    }
}

struct BudgetRow: View {
    let name: String
    let spent: Double
    let ceiling: Double
    let remainingLabel: String   // e.g. "Kvar"
    let overLabel: String        // e.g. "Över tak med"

    private var state: BudgetBarState { BudgetBarState.classify(spent: spent, ceiling: ceiling) }
    private func money(_ v: Double) -> String { Utility.doubleToLocalCurrency(value: v) }
    private var restColor: Color {
        switch state { case .over: return .appRed; case .warn: return .appAmber; case .normal: return .appPineInk }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Text(name).font(.system(size: 15, weight: .semibold)).foregroundColor(.appInk)
                Spacer()
                (Text(money(spent)).foregroundColor(state == .over ? .appRed : .appInk)
                 + Text(" / \(money(ceiling))").foregroundColor(.appMuted))
                    .font(.mono(13, weight: .regular))
            }
            TakBar(spent: spent, ceiling: ceiling)
            if state == .over {
                (Text("\(overLabel) ").foregroundColor(.appMuted)
                 + Text(money(spent - ceiling)).foregroundColor(restColor))
                    .font(.system(size: 12))
            } else {
                (Text("\(remainingLabel) ").foregroundColor(.appMuted)
                 + Text(money(ceiling - spent)).foregroundColor(restColor))
                    .font(.system(size: 12))
            }
        }
        .padding(.vertical, 13).padding(.horizontal, 18)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            HeroCard(label: "Kvar av månadens budget",
                     summary: HomeSummary(income: 36628, rows: [(14768.7, 30154)]),
                     incomeLabel: "Inkomst", spentLabel: "Spenderat", ceilingLabel: "Budgettak")
            AccountRow(name: "Sparkonto", meta: "Uppdaterat 20:00", amount: 103877.52,
                       deviation: 798.8, onTap: {})
            AccountRow(name: "ISK", meta: "Uppdaterat 20:00", amount: 66100, deviation: nil, onTap: nil)
            AppCard(padding: 0) {
                VStack(spacing: 0) {
                    BudgetRow(name: "Nöje", spent: 3357, ceiling: 1200, remainingLabel: "Kvar", overLabel: "Över tak med")
                    Divider().overlay(Color.appLine)
                    BudgetRow(name: "Fika", spent: 242.5, ceiling: 400, remainingLabel: "Kvar", overLabel: "Över tak med")
                }
            }
        }.padding()
    }.background(Color.appBackground)
}
