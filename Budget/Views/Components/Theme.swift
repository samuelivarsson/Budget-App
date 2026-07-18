import SwiftUI

// Colors whose asset names camel-case to the exact symbol we want
// (appBackground, heroTop, heroBottom, heroInk, heroMuted, heroTrack, heroFill)
// are provided by Xcode's auto-generated asset symbols, so they are not
// re-declared here to avoid "invalid redeclaration" errors.
extension Color {
    static let appCard       = Color("Card")
    static let appCard2      = Color("Card2")
    static let appInk        = Color("Ink")
    static let appMuted      = Color("Muted")
    static let appLine       = Color("Line")
    static let appPine       = Color("Pine")
    static let appPineInk    = Color("PineInk")
    static let appPineSoft   = Color("PineSoft")
    static let appAmber      = Color("Amber")
    static let appAmberBar   = Color("AmberBar")
    static let appAmberSoft  = Color("AmberSoft")
    static let appRed        = Color("Red")
    static let appRedBar     = Color("RedBar")
    static let appRedSoft    = Color("RedSoft")
    static let appTrack      = Color("Track")
    static let appInfo       = Color("Info")
    static let appInfoSoft   = Color("InfoSoft")
    static let appChipBg     = Color("ChipBg")
}

extension Font {
    static func mono(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

enum BudgetBarState {
    case normal, warn, over
    static let defaultWarnThreshold = 0.5
    static func classify(spent: Double, ceiling: Double,
                         warnThreshold: Double = defaultWarnThreshold) -> BudgetBarState {
        if ceiling <= 0 { return spent > 0 ? .over : .normal }
        if spent > ceiling { return .over }
        return (spent / ceiling) >= warnThreshold ? .warn : .normal
    }
}

enum CategoryPalette {
    static let colorNames = ["Cat0", "Cat1", "Cat2", "Cat3", "Cat4", "Cat5", "Cat6", "Cat7"]
    static let fixed: [String: Int] = [
        "Sparkonto köp": 0, "Fika": 1, "Nöje": 2, "Mat": 3,
        "Livsmedel": 4, "Transport": 5, "Resor": 6, "Övrigt": 7,
    ]
    static func index(for name: String) -> Int {
        if let i = fixed[name] { return i }
        var hash = 0
        for u in name.unicodeScalars { hash = hash &* 31 &+ Int(u.value) }
        return abs(hash) % colorNames.count
    }
}

extension Color {
    static func forCategory(_ name: String) -> Color {
        Color(CategoryPalette.colorNames[CategoryPalette.index(for: name)])
    }
}
