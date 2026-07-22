//
//  HistoryIOSComponents.swift
//  Budget
//
//  iOS 26 styled building blocks for the History screen.
//  Solid fills / system colors only — no backdrop-blur materials (scroll perf).
//

import SwiftUI

// MARK: - Period

enum HistoryPeriod: CaseIterable {
    case month, threeMonths, year, all
    var title: String {
        switch self {
        case .month: return "thisMonth"
        case .threeMonths: return "threeMonths"
        case .year: return "thisYear"
        case .all: return "allTime"
        }
    }
}

// MARK: - Category stat

struct CategoryStat: Identifiable {
    let id: String
    let name: String
    let type: TransactionType
    let total: Double
}

// MARK: - Type colors

enum HistoryColors {
    static let expense  = Color(red: 1.0, green: 0.36, blue: 0.32)
    static let income   = Color(red: 0.18, green: 0.82, blue: 0.35)
    static let saving   = Color(red: 0.22, green: 0.82, blue: 0.88)
    static let transfer = Color(red: 0.06, green: 0.71, blue: 0.79)
    static let negative = Color(red: 0.90, green: 0.20, blue: 0.18)

    static func dot(for type: TransactionType) -> Color {
        switch type {
        case .expense: return expense
        case .income:  return income
        case .transfer:  return saving
        }
    }
}

// MARK: - Period selector

struct IOSHistoryPeriodBar: View {
    @Binding var selection: HistoryPeriod
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(HistoryPeriod.allCases, id: \.self) { p in
                    let active = selection == p
                    Button { selection = p } label: {
                        Text(LocalizedStringKey(p.title))
                            .font(.system(size: 13, weight: .semibold))
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

// MARK: - Summary card

struct IOSHistorySummary: View {
    let title: String
    let value: String
    let valueColor: Color
    var subtitleLabel: String? = nil    // e.g. "Sparkonto köp"
    var subtitleValue: String? = nil    // bold amount after the label
    var subtitlePlain: String? = nil    // plain trailing note (e.g. "insatt på sparkonton")
    // Optional second subtitle line.
    var line2Label: String? = nil
    var line2Value: String? = nil
    var line2ValueColor: Color = .primary

    private func subLine<L: View>(@ViewBuilder _ content: () -> L) -> some View {
        content().lineLimit(1).minimumScaleFactor(0.7)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(LocalizedStringKey(title))
                .font(.system(size: 11.5, weight: .semibold)).foregroundColor(.secondary)
                .lineLimit(1).minimumScaleFactor(0.8)
            Text(value)
                .font(.system(size: 17.5, weight: .bold)).foregroundColor(valueColor)
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
            subLine {
                HStack(spacing: 4) {
                    if let subtitleLabel {
                        Text(LocalizedStringKey(subtitleLabel)).font(.system(size: 10.5)).foregroundColor(.secondary)
                    }
                    if let subtitleValue {
                        Text(subtitleValue).font(.system(size: 10.5, weight: .bold)).foregroundColor(.primary).monospacedDigit()
                    }
                    if let subtitlePlain {
                        Text(LocalizedStringKey(subtitlePlain)).font(.system(size: 10.5)).foregroundColor(.secondary)
                    }
                }
            }
            if line2Label != nil || line2Value != nil {
                subLine {
                    HStack(spacing: 4) {
                        if let line2Label {
                            Text(LocalizedStringKey(line2Label)).font(.system(size: 10.5)).foregroundColor(.secondary)
                        }
                        if let line2Value {
                            Text(line2Value).font(.system(size: 10.5, weight: .bold)).foregroundColor(line2ValueColor).monospacedDigit()
                        }
                    }
                }
            }
        }
        // maxHeight: .infinity so both cards stretch to the taller one (in an HStack
        // the height resolves to the tallest sibling, keeping the boxes equal).
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 13).padding(.vertical, 12)
        .iosCard(22)
    }
}

// MARK: - Section head

struct IOSStatSectionHead: View {
    let title: String
    var dotColor: Color? = nil
    var total: String? = nil
    var body: some View {
        HStack(spacing: 8) {
            if let dotColor { Circle().fill(dotColor).frame(width: 8, height: 8) }
            Text(LocalizedStringKey(title)).font(.system(size: 18, weight: .bold)).foregroundColor(.primary)
            Spacer()
            if let total {
                Text(total).font(.system(size: 13.5, weight: .bold)).foregroundColor(.secondary).monospacedDigit()
            }
        }
        .padding(.horizontal, 6).padding(.top, 20).padding(.bottom, 10)
    }
}

// MARK: - Stat row (bar) + card

struct IOSStatRow: View {
    let name: String
    let amount: String
    let color: Color
    let fraction: Double      // bar fill 0...1 (relative to section max)
    var percent: String? = nil

    var body: some View {
        VStack(spacing: 7) {
            HStack(spacing: 7) {
                Circle().fill(color).frame(width: 7, height: 7)
                Text(name).font(.system(size: 14.5, weight: .semibold)).foregroundColor(.primary).lineLimit(1)
                Spacer(minLength: 6)
                if let percent {
                    Text(percent).font(.system(size: 11.5, weight: .semibold)).foregroundColor(.secondary).monospacedDigit()
                }
                Text(amount).font(.system(size: 14, weight: .bold)).foregroundColor(.primary).monospacedDigit()
            }
            // scaleEffect-based bar (no GeometryReader) for smooth scrolling
            Capsule().fill(Color.primary.opacity(0.10))
                .frame(height: 5)
                .overlay(alignment: .leading) {
                    Capsule().fill(color)
                        .frame(height: 5)
                        .scaleEffect(x: max(0.02, min(fraction, 1)), y: 1, anchor: .leading)
                }
        }
        .padding(.vertical, 11)
    }
}

struct IOSStatCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack(spacing: 0) { content }
            .padding(.horizontal, 16)
            .iosCard(22)
    }
}
