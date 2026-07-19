//
//  StandingsIOSComponents.swift
//  Budget
//
//  iOS 26 styled building blocks for the Standings screen.
//  Solid fills / system colors only — no backdrop-blur materials (scroll perf).
//

import SwiftUI

// MARK: - Palette

enum StandingColors {
    /// Teal used for "you owe" — same hue as the debt chips in the transaction list.
    static let owe = Color(red: 0.06, green: 0.71, blue: 0.79)
    static let get = Color.green
}

// MARK: - Kind / action classification

enum StandingKind {
    case owe   // I owe the friend (negative)
    case get   // The friend owes me (positive)
    case even  // Settled

    static func classify(_ amount: Double) -> StandingKind {
        let cents = round(amount * 100)
        if cents < 0 { return .owe }
        if cents > 0 { return .get }
        return .even
    }
}

// MARK: - Summary cards

struct IOSStandingSummary: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(LocalizedStringKey(title))
                .font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 18, weight: .bold)).foregroundColor(color)
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
            Text(subtitle)
                .font(.system(size: 11)).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14).padding(.vertical, 13)
        .iosCard(22)
    }
}

// MARK: - Filter

enum StandingFilter: CaseIterable {
    case all, toSettle
    var title: String {
        switch self {
        case .all: return "all"
        case .toSettle: return "toSettle"
        }
    }
}

struct IOSStandingFilterBar: View {
    @Binding var selection: StandingFilter
    let toSettleCount: Int
    var body: some View {
        HStack(spacing: 8) {
            ForEach(StandingFilter.allCases, id: \.self) { f in
                let active = selection == f
                Button { selection = f } label: {
                    HStack(spacing: 6) {
                        Text(LocalizedStringKey(f.title)).font(.system(size: 13, weight: .semibold))
                        if f == .toSettle {
                            Text("\(toSettleCount)")
                                .font(.system(size: 11, weight: .bold)).monospacedDigit()
                                .padding(.horizontal, 6).padding(.vertical, 1)
                                .background(active ? Color.iosBG.opacity(0.25) : StandingColors.owe.opacity(0.16))
                                .foregroundColor(active ? Color.iosBG : StandingColors.owe)
                                .clipShape(Capsule())
                        }
                    }
                    .foregroundColor(active ? Color.iosBG : .secondary)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(active ? Color.primary : Color.iosCardFill)
                    .overlay(Capsule().strokeBorder(Color.primary.opacity(active ? 0 : 0.06), lineWidth: 1))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Standing row

struct IOSStandingRow: View {
    let name: String
    let id: String
    let amount: Double        // signed: negative = I owe, positive = they owe me
    let isCustom: Bool        // account-less custom contact
    let money: (Double) -> String
    let onAction: () -> Void

    private var kind: StandingKind { StandingKind.classify(amount) }

    private var subtitle: String? {
        switch kind {
        case .owe: return "youAreOwingShort".localizeString()
        case .get: return isCustom
            ? "\("owesYou".localizeString()) · \("withoutAccount".localizeString())"
            : "owesYou".localizeString()
        case .even: return isCustom ? "withoutAccount".localizeString() : nil
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                IOSPersonAvatar(name: name, id: id, size: 38)
                if isCustom {
                    Circle()
                        .strokeBorder(Color.primary.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                        .frame(width: 44, height: 44)
                }
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(name).font(.system(size: 15.5, weight: .semibold)).foregroundColor(.primary).lineLimit(1)
                if let subtitle {
                    Text(subtitle).font(.system(size: 12)).foregroundColor(.secondary).lineLimit(1)
                }
            }
            Spacer(minLength: 6)
            if kind == .even {
                Text("even")
                    .font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)
                    .padding(.horizontal, 11).padding(.vertical, 4)
                    .background(Color.primary.opacity(0.08)).clipShape(Capsule())
            } else {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(amountText)
                        .font(.system(size: 15, weight: .bold)).monospacedDigit()
                        .foregroundColor(kind == .owe ? StandingColors.owe : StandingColors.get)
                    actionPill
                }
            }
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private var amountText: String {
        kind == .get ? "+" + money(amount) : money(amount)
    }

    private var actionPill: some View {
        let (label, symbol): (String, String) = {
            switch kind {
            case .owe: return ("settleUp", "arrow.up.right")
            case .get: return isCustom ? ("regulate", "checkmark") : ("remindButton", "bell.fill")
            case .even: return ("", "")
            }
        }()
        return Button(action: onAction) {
            HStack(spacing: 4) {
                Image(systemName: symbol).font(.system(size: 10, weight: .bold))
                Text(LocalizedStringKey(label)).font(.system(size: 11.5, weight: .bold))
            }
            .foregroundColor(.accentColor)
            .padding(.horizontal, 10).padding(.vertical, 3.5)
            .background(Color.accentColor.opacity(0.12)).clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Standing list card

struct IOSStandingCard<Row: View>: View {
    let count: Int
    let showMore: Bool
    let moreCount: Int
    let onShowMore: () -> Void
    @ViewBuilder let row: (Int) -> Row

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0 ..< count, id: \.self) { i in
                if i > 0 { Divider().overlay(Color.iosBorder).padding(.leading, 50) }
                row(i)
            }
            if showMore {
                Divider().overlay(Color.iosBorder).padding(.leading, 50)
                Button(action: onShowMore) {
                    HStack(spacing: 6) {
                        Text(String(format: "showMoreCount".localizeString(), moreCount))
                        Image(systemName: "chevron.down").font(.system(size: 12, weight: .bold))
                    }
                    .font(.system(size: 13.5, weight: .semibold)).foregroundColor(.accentColor)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .iosCard(22)
    }
}
