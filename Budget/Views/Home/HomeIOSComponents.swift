//
//  HomeIOSComponents.swift
//  Budget
//
//  iOS 26 "liquid glass" styled building blocks for the Home screen (v3).
//  Uses system materials and semantic colors rather than the pine token set.
//

import SwiftUI

// MARK: - iOS surface tokens
// Darker, closer to the mockup than the system grays. Translucent card fills are
// cheap (alpha compositing, no blur) so they don't affect scroll performance.
extension Color {
    static let iosBG = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(white: 0.02, alpha: 1)                                   // ~#050507
        : UIColor(red: 0.957, green: 0.957, blue: 0.972, alpha: 1) })      // ~#f4f4f8
    static let iosCardFill = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(white: 1, alpha: 0.055)
        : UIColor.white })
    static let iosBorder = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(white: 1, alpha: 0.09)
        : UIColor(white: 0, alpha: 0.06) })
}

// MARK: - Glass card

struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            // Solid fill rather than .ultraThinMaterial: a backdrop-blur material
            // re-composites on every scroll frame and was the source of the
            // scroll lag on this screen. The solid secondary-system-background
            // reads almost identically while scrolling smoothly.
            .background(Color.iosCardFill, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            )
    }
}

struct IOSSectionHead: View {
    let title: String
    var trailing: String? = nil
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(LocalizedStringKey(title)).font(.system(size: 20, weight: .bold)).foregroundColor(.primary)
            Spacer()
            if let trailing {
                Text(trailing).font(.system(size: 14, weight: .semibold)).foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 6).padding(.top, 22).padding(.bottom, 10)
    }
}

// MARK: - Account icon + visuals

enum AccountVisuals {
    static let priv:  [Color] = [Color(red: 0.04, green: 0.52, blue: 1.00), Color(red: 0.29, green: 0.66, blue: 1.00)]
    static let fixed: [Color] = [Color(red: 0.37, green: 0.36, blue: 0.90), Color(red: 0.49, green: 0.48, blue: 1.00)]
    static let isk:   [Color] = [Color(red: 0.18, green: 0.71, blue: 0.42), Color(red: 0.20, green: 0.78, blue: 0.35)]
    static let trip:  [Color] = [Color(red: 1.00, green: 0.62, blue: 0.04), Color(red: 1.00, green: 0.75, blue: 0.27)]
    static let save:  [Color] = [Color(red: 0.06, green: 0.71, blue: 0.79), Color(red: 0.22, green: 0.82, blue: 0.88)]

    static func visual(for account: Account, isMain: Bool) -> (symbol: String, colors: [Color]) {
        let n = account.name.lowercased()
        if n.contains("resor") || n.contains("trip") || n.contains("travel") { return ("airplane", trip) }
        if n.contains("isk") || n.contains("invest") { return ("chart.line.uptrend.xyaxis", isk) }
        if n.contains("spar") || n.contains("saving") { return ("banknote.fill", save) }
        if n.contains("fast") || n.contains("fixed") || account.type == .overhead { return ("calendar", fixed) }
        if isMain || account.type == .transaction { return ("creditcard.fill", priv) }
        return ("wallet.pass.fill", priv)
    }

    static func dotColor(for account: Account) -> Color {
        visual(for: account, isMain: false).colors.first ?? .accentColor
    }
}

struct AccountIcon: View {
    let account: Account
    var isMain: Bool = false
    var body: some View {
        let v = AccountVisuals.visual(for: account, isMain: isMain)
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(LinearGradient(colors: v.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 38, height: 38)
            .overlay(Image(systemName: v.symbol).font(.system(size: 16, weight: .semibold)).foregroundColor(.white))
    }
}

// MARK: - Budget ring

struct BudgetRing: View {
    let progress: Double // 0...1 (display), color reflects state
    let color: Color
    let label: String
    var body: some View {
        ZStack {
            Circle().stroke(Color.primary.opacity(0.12), lineWidth: 5)
            Circle().trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(label).font(.system(size: 10.5, weight: .bold)).foregroundColor(color)
                .monospacedDigit()
        }
        .frame(width: 46, height: 46)
    }
}

// MARK: - Budget state colors

extension BudgetBarState {
    var tint: Color {
        switch self {
        case .over: return .red
        case .warn: return Color(red: 1.0, green: 0.72, blue: 0.10)
        case .normal: return .green
        }
    }
}

// MARK: - Budget row

struct IOSBudgetRow: View {
    let name: String
    let spent: Double
    let ceiling: Double
    var dotColor: Color? = nil
    var showsTopDivider: Bool = true

    private var state: BudgetBarState { BudgetBarState.classify(spent: spent, ceiling: ceiling) }
    private var ratio: Double {
        if state == .over { return 1 }
        return ceiling <= 0 ? 0 : min(max(spent / ceiling, 0), 1)
    }
    private func money(_ v: Double) -> String { Utility.doubleToLocalCurrency(value: v) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showsTopDivider {
                Divider().overlay(Color.primary.opacity(0.06))
            }
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                HStack(spacing: 6) {
                    if let dotColor {
                        Circle().fill(dotColor).frame(width: 7, height: 7)
                    }
                    Text(LocalizedStringKey(name)).font(.system(size: 15.5, weight: .semibold)).foregroundColor(.primary)
                    if state == .over {
                        Text("overCeiling")
                            .font(.system(size: 10, weight: .bold)).kerning(0.4).textCase(.uppercase)
                            .foregroundColor(.red)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Color.red.opacity(0.14)).clipShape(Capsule())
                    }
                }
                Spacer()
                (Text(money(spent)).foregroundColor(.primary).fontWeight(.semibold)
                 + Text(" / \(money(ceiling))").foregroundColor(.secondary))
                    .font(.system(size: 13)).monospacedDigit()
            }
            HStack(spacing: 10) {
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.12))
                    Rectangle().fill(state.tint).scaleEffect(x: ratio, y: 1, anchor: .leading)
                }
                .frame(height: 6)
                .clipShape(Capsule())
                let remaining = ceiling - spent
                Text(remaining >= 0 ? "\(money(remaining)) \("remainingShort".localizeString().lowercased())" : money(remaining))
                    .font(.system(size: 12.5, weight: .semibold)).monospacedDigit()
                    .foregroundColor(remaining >= 0 ? .green : .red)
                    .frame(minWidth: 92, alignment: .trailing)
            }
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Account rows

/// Row for a quick-balance ("snabbsaldo") account. Uses @AppStorage so it
/// re-renders and animates when a refresh completes; tapping refreshes.
struct IOSQuickBalanceRow: View {
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var quickBalanceViewModel: QuickBalanceViewModel

    @AppStorage private var quickBalance: Double
    @AppStorage private var lastUpdate: String
    @State private var animate = false

    let account: Account
    let balance: Double
    let isMain: Bool
    let quickBalanceAccount: QuickBalanceAccount

    init(account: Account, balance: Double, isMain: Bool, quickBalanceAccount: QuickBalanceAccount) {
        self.account = account
        self.balance = balance
        self.isMain = isMain
        self.quickBalanceAccount = quickBalanceAccount
        self._quickBalance = AppStorage(wrappedValue: 0, "QuickBalance:" + account.id, store: QuickBalanceViewModel.sharedUserDefaults)
        self._lastUpdate = AppStorage(wrappedValue: "-", "LastUpdate:" + account.id, store: QuickBalanceViewModel.sharedUserDefaults)
    }

    private var diff: Double { quickBalance - balance }
    private var isZero: Bool { abs(round(quickBalance * 100) - round(balance * 100)) < 0.5 }

    private var lastUpdateText: String {
        if let date = Utility.stringToDate(string: lastUpdate, style: .short, timeStyle: .medium) {
            let f = DateFormatter()
            f.locale = Locale(identifier: Locale.preferredLanguages.first ?? "sv")
            f.dateFormat = "d MMM HH:mm"
            return f.string(from: date)
        }
        return lastUpdate
    }

    var body: some View {
        Button {
            quickBalanceViewModel.fetchQuickBalanceFromApi(quickBalanceAccount: quickBalanceAccount) { error in
                if let error = error { errorHandling.handle(error: error) }
            }
        } label: {
            HStack(spacing: 13) {
                AccountIcon(account: account, isMain: isMain)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(account.name).font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                            .lineLimit(1).minimumScaleFactor(0.6)
                        if isMain { mainBadge.layoutPriority(1) }
                    }
                    Text("\("snabbsaldo".localizeString()) \(Utility.doubleToLocalCurrency(value: quickBalance))")
                        .font(.system(size: 12)).foregroundColor(.secondary).monospacedDigit()
                    Text("\("updatedAt".localizeString()) \(lastUpdateText)")
                        .font(.system(size: 12)).foregroundColor(.secondary)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 3) {
                    Text(Utility.doubleToLocalCurrency(value: balance))
                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.primary).monospacedDigit()
                        .scaleEffect(animate ? 1.1 : 1)
                    diffChip
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .animation(.spring(dampingFraction: 0.5), value: animate)
        .onChange(of: lastUpdate) { _ in
            animate = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { animate = false }
        }
    }

    private var mainBadge: some View {
        Text("mainAccount")
            .font(.system(size: 9.5, weight: .bold)).kerning(0.5).textCase(.uppercase)
            .foregroundColor(.accentColor)
            .lineLimit(1).fixedSize()
            .padding(.horizontal, 7).padding(.vertical, 2)
            .background(Color.accentColor.opacity(0.12)).clipShape(Capsule())
    }

    private var diffChip: some View {
        let text = isZero ? "±0 kr" : (diff > 0 ? "+" : "−") + Utility.doubleToLocalCurrency(value: abs(diff))
        return Text(text)
            .font(.system(size: 12, weight: .semibold)).monospacedDigit()
            .foregroundColor(isZero ? .secondary : .green)
            .padding(.horizontal, 8).padding(.vertical, 2.5)
            .background(isZero ? Color.primary.opacity(0.10) : Color.green.opacity(0.15))
            .clipShape(Capsule())
    }
}

/// Plain account row (no quick balance) — e.g. ISK.
struct IOSAccountRow: View {
    let account: Account
    let balance: Double
    var isMain: Bool = false
    var subtitle: String? = nil
    var body: some View {
        HStack(spacing: 13) {
            AccountIcon(account: account, isMain: isMain)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(account.name).font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                }
                if let subtitle {
                    Text(subtitle).font(.system(size: 12)).foregroundColor(.secondary)
                }
            }
            Spacer(minLength: 8)
            Text(Utility.doubleToLocalCurrency(value: balance))
                .font(.system(size: 16, weight: .semibold)).foregroundColor(.primary).monospacedDigit()
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}

// MARK: - Group label

struct IOSGroupLabel: View {
    let title: String
    var dotColor: Color? = nil
    var topBorder: Bool = false
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if topBorder {
                Divider().overlay(Color.primary.opacity(0.06)).padding(.bottom, 14)
            }
            HStack(spacing: 7) {
                if let dotColor { Circle().fill(dotColor).frame(width: 7, height: 7) }
                Text(LocalizedStringKey(title)).font(.system(size: 11, weight: .bold)).kerning(0.7)
                    .textCase(.uppercase).foregroundColor(.secondary)
                Spacer(minLength: 0)
            }
            .padding(.top, topBorder ? 0 : 14).padding(.bottom, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
