import SwiftUI

struct AppCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .background(Color.appCard)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.appLine, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
    }
}

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil
    init(_ title: String, trailing: String? = nil) { self.title = title; self.trailing = trailing }
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .bold)).kerning(1)
                .foregroundColor(.appMuted)
            Spacer()
            if let trailing {
                Text(trailing).font(.mono(13, weight: .regular)).foregroundColor(.appMuted)
            }
        }
        .padding(.horizontal, 4)
    }
}

struct Chip: View {
    enum Style { case deviation, ok }
    let text: String
    let style: Style
    init(_ text: String, style: Style) { self.text = text; self.style = style }
    private var fg: Color { style == .ok ? .appPineInk : .appRed }
    private var bg: Color { style == .ok ? .appPineSoft : .appRedSoft }
    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(fg).frame(width: 6, height: 6)
            Text(text).font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 8).padding(.vertical, 3)
        .foregroundColor(fg).background(bg).clipShape(Capsule())
    }
}

/// A progress bar showing how much of a category's ceiling has been used.
/// The fill width is `spent / ceiling` (0–100%); when the ceiling is exceeded
/// the bar is full and turns red. Amber warns at ≥50% of the ceiling.
struct TakBar: View {
    let spent: Double
    let ceiling: Double
    private var state: BudgetBarState { BudgetBarState.classify(spent: spent, ceiling: ceiling) }
    private var ratio: Double { ceiling <= 0 ? (spent > 0 ? 1 : 0) : min(max(spent / ceiling, 0), 1) }
    private var fillRatio: Double { state == .over ? 1 : ratio }
    private var fillColor: Color {
        switch state {
        case .over: return .appRedBar
        case .warn: return .appAmberBar
        case .normal: return .appPine
        }
    }
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.appTrack)
                Capsule().fill(fillColor).frame(width: geo.size.width * fillRatio)
            }
        }
        .frame(height: 8)
    }
}

struct SplitBar: View {
    let percent: Double // 0..100
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.appTrack)
                Capsule().fill(Color.appPine)
                    .frame(width: geo.size.width * min(max(percent / 100, 0), 1))
            }
        }
        .frame(height: 5)
    }
}

struct ScreenHeader<Trailing: View>: View {
    let eyebrow: String
    let title: String
    @ViewBuilder var trailing: Trailing
    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(eyebrow.uppercased())
                    .font(.system(size: 12, weight: .semibold)).kerning(1)
                    .foregroundColor(.appMuted)
                Text(title).font(.system(size: 30, weight: .bold)).foregroundColor(.appInk)
            }
            Spacer()
            trailing
        }
        .padding(.horizontal, 4)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        VStack(spacing: 16) {
            ScreenHeader(eyebrow: "Juli 2026", title: "Hem") {
                Image(systemName: "bell").foregroundColor(.appMuted)
            }
            SectionHeader("Konton", trailing: "Totalt 190 167,10 kr")
            AppCard { HStack { Text("Nöje").foregroundColor(.appInk); Spacer(); Chip("Avviker +12", style: .deviation) } }
            AppCard { VStack(spacing: 10) {
                TakBar(spent: 3357, ceiling: 1200)
                TakBar(spent: 242.5, ceiling: 400)
                TakBar(spent: 100, ceiling: 400)
                SplitBar(percent: 56)
            } }
        }.padding()
    }
}
