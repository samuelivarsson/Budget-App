//
//  Utility.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-15.
//

import Firebase
import FirebaseAuth
import FirebaseCore
import FirebaseStorage
import Foundation
import SwiftUI

/// Offers useful utilities
class Utility {
    static var currencyFormatter: NumberFormatter {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.isPartialStringValidationEnabled = true
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale.current
        currencyFormatter.maximumFractionDigits = 2
        currencyFormatter.minimumFractionDigits = 2
        return currencyFormatter
    }
    
    static var currencyFormatterNoSymbol: NumberFormatter {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.isPartialStringValidationEnabled = true
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.maximumFractionDigits = 2
        currencyFormatter.minimumFractionDigits = 2
        return currencyFormatter
    }
    
    static var currencyFormatterNoSymbolNoZeroSymbol: NumberFormatter {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.isPartialStringValidationEnabled = true
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.maximumFractionDigits = 2
        currencyFormatter.minimumFractionDigits = 2
        currencyFormatter.zeroSymbol = ""
        return currencyFormatter
    }
    
    /// Converts any Double to Double with only 2 decimals
    static func doubleToTwoDecimals(value: Double) -> Double {
        let newValue = String(format: "%.2f", value)
        guard let result = Double(newValue) else {
            let info = "Error when converting String to Double in doubleToTwoDecimals in Utility"
            print(info)
            return value
        }
        return result
    }
    
    /// Converts any Double to Double with only 2 decimals rounded down
    static func doubleToTwoDecimalsFloored(value: Double) -> Double {
        let decimals = pow(10.0, Double(2))
        let result = floor(value * decimals) / decimals
        return result
    }
    
    /// Converts a double to a string representing the value as a currency
    static func doubleToLocalCurrency(value: Double) -> String {
        guard let result: String = self.currencyFormatter.string(from: value as NSNumber) else {
            return "Error when formatting to local currency"
        }
        return result
    }

    /// Fetches an image from an url and returns a UIImage
    static func getImageFromURL(url: URL?, completion: @escaping (_ uiImage: UIImage?, _ error: Error?) -> Void) {
        guard let url = url else {
            let info = "Found nil when extracting url in getImageFromURL in Utility"
            print(info)
            completion(nil, ApplicationError.unexpectedNil(info))
            return
        }
        DispatchQueue.global().async {
            guard let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) else {
                completion(nil, NetworkError.imageFetch)
                return
            }

            completion(uiImage, nil)
        }
    }

    /// Takes a UIImage and uploads it to FirebaseStorage, returns the URL of the uploaded image
    static func uploadMedia(image: UIImage, completion: @escaping (_ url: URL?, _ error: Error?) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        guard let uid = Auth.auth().currentUser?.uid else {
            let info = "Found nil when extracting uid in uploadMedia in Utility"
            print(info)
            completion(nil, ApplicationError.unexpectedNil(info))
            return
        }
        let imageRef = storageRef.child("users/\(uid)/profilePicture.png")
        if let uploadData = image.jpegData(compressionQuality: 0.5) {
            imageRef.putData(uploadData, metadata: nil) { _, error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                imageRef.downloadURL { url, error in
                    if let error = error {
                        completion(nil, error)
                        return
                    }

                    // Success
                    completion(url, nil)
                }
            }
        } else {
            let info = "Failed to turn image into jpegData in uploadMedia in TransactionView"
            print(info)
            completion(nil, ApplicationError.unexpectedNil(info))
        }
    }

    static func getProfilePictureFromUID(uid: String?, failImage: UIImage? = nil, completion: @escaping (UIImage?, Error?) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        guard let uid = uid else {
            let info = "Found nil when extracting uid in getProfilePictureFromUID in TransactionView"
            print(info)
            completion(nil, ApplicationError.unexpectedNil(info))
            return
        }
        let imageRef = storageRef.child("users/\(uid)/profilePicture.png")
        imageRef.downloadURL { url, error in
            if let error = error {
                completion(failImage, error)
                return
            }
            guard let url = url else {
                let info = "Found nil when extracting url in getProfilePictureFromUID in TransactionView"
                print(info)
                completion(failImage, ApplicationError.unexpectedNil(info))
                return
            }
            getImageFromURL(url: url) { uiImage, error in
                if let error = error {
                    completion(failImage, error)
                    return
                }
                guard let uiImage = uiImage else {
                    let info = "Found nil when extracting uiImage in getProfilePictureFromUID in TransactionView"
                    print(info)
                    completion(failImage, ApplicationError.unexpectedNil(info))
                    return
                }

                completion(uiImage, nil)
            }
        }
    }

    /// Get the current budget period based on when the user wants to start and end the budget-month
    static func getBudgetPeriod(monthsBack: Int = 0, monthStartsOn: Int) -> (Date, Date) {
        var fromDate: Date
        var toDate: Date
        let calendar = Calendar.current
        let referenceDate = calendar.date(byAdding: .month, value: -monthsBack, to: Date()) ?? Date()

        if calendar.dateComponents([.day], from: referenceDate).day! < monthStartsOn {
            var dayComponent = DateComponents()
            dayComponent.day = monthStartsOn
            toDate = calendar.nextDate(
                after: referenceDate,
                matching: dayComponent,
                matchingPolicy: .nextTime,
                repeatedTimePolicy: .first,
                direction: .forward
            ) ?? Date()

            fromDate = calendar.date(byAdding: .month, value: -1, to: toDate) ?? Date()
        } else {
            var dayComponent = DateComponents()
            dayComponent.day = monthStartsOn
            fromDate = calendar.nextDate(
                after: referenceDate,
                matching: dayComponent,
                matchingPolicy: .nextTime,
                repeatedTimePolicy: .last,
                direction: .backward
            ) ?? Date()

            toDate = calendar.date(byAdding: .month, value: 1, to: fromDate) ?? Date()
        }

        return (fromDate, toDate)
    }

    static func getTimePassed(since date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)

        let years = seconds / (60.0 * 60.0 * 24.0 * 365.2422)
        let months = seconds / (60.0 * 60.0 * 24.0 * 30.4369)
        let weeks = seconds / (60.0 * 60.0 * 24.0 * 7.0)
        let days = seconds / (60.0 * 60.0 * 24.0)
        let hours = seconds / (60.0 * 60.0)
        let minutes = seconds / 60.0

        if years >= 1 {
            return "\(Int(years)) " + NSLocalizedString("shortYears", comment: "")
        }
        if months >= 1 {
            return "\(Int(months)) " + NSLocalizedString("shortMonths", comment: "")
        }
        if weeks >= 1 {
            return "\(Int(weeks)) " + NSLocalizedString("shortWeeks", comment: "")
        }
        if days >= 1 {
            return "\(Int(days)) " + NSLocalizedString("shortDays", comment: "")
        }
        if hours >= 1 {
            return "\(Int(hours)) " + NSLocalizedString("shortHours", comment: "")
        }
        if minutes >= 1 {
            return "\(Int(minutes)) " + NSLocalizedString("shortMinutes", comment: "")
        }

        return "\(Int(seconds)) " + NSLocalizedString("shortSeconds", comment: "")
    }
}

extension Color {
    #if os(macOS)
    static let background = Color(NSColor.windowBackgroundColor)
    static let secondaryBackground = Color(NSColor.underPageBackgroundColor)
    static let tertiaryBackground = Color(NSColor.controlBackgroundColor)
    #else
    static let background = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
    #endif

    /// Create a color with hex-code
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

/// A view that shows an optional UIImage, if nil, its shows the failImage.
struct ProfilePicture: View {
    let uiImage: UIImage?
    let failImage: Image
    let fill: Bool = true

    var body: some View {
        if let uiImage = uiImage {
            if fill {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(uiImage: uiImage)
            }
        } else {
            if fill {
                failImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                failImage
            }
        }
    }
}

/// A generic TextField with icon
struct IconTextField: View {
    @Binding var text: String
    var imgName: String
    var placeHolderText: LocalizedStringKey
    var disableAutocorrection: Bool = false
    var autoCapitalization: TextInputAutocapitalization = .words
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack {
            Image(systemName: imgName).foregroundColor(.secondary)
            TextField(placeHolderText, text: $text)
                .keyboardType(keyboardType)
                .disableAutocorrection(disableAutocorrection)
                .textInputAutocapitalization(autoCapitalization)
        }
        .frame(height: 20)
    }
}

/// A generic field for entering a password
struct PasswordField: View {
    @Binding var password: String

    @State private var showPassword = false

    var body: some View {
        HStack {
            Image(systemName: "lock").foregroundColor(.secondary)
            if showPassword {
                TextField("password", text: $password)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.none)
            } else {
                SecureField("password", text: $password)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.none)
            }
            Button {
                self.showPassword.toggle()
            } label: {
                Image(systemName: "eye").foregroundColor(.secondary)
            }
        }
        .frame(height: 20)
    }
}

/// View extension onLoad
struct ViewDidLoadModifier: ViewModifier {
    @State private var didLoad = false
    private let action: (() -> Void)?

    init(perform action: (() -> Void)? = nil) {
        self.action = action
    }

    func body(content: Content) -> some View {
        content.onAppear {
            if didLoad == false {
                didLoad = true
                action?()
            }
        }
    }
}

extension View {
    func onLoad(perform action: (() -> Void)? = nil) -> some View {
        modifier(ViewDidLoadModifier(perform: action))
    }
}

struct MyBadge: View {
    let count: Int

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear
            Text(String(count))
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .padding(5)
                .background(Color.red)
                .clipShape(Circle())
                // custom positioning in the top-right corner
                .alignmentGuide(.top) { $0[.bottom] }
                .alignmentGuide(.trailing) { $0[.trailing] - $0.width * 0.25 }
        }
    }
}

struct MyBadgeModifier: ViewModifier {
    let count: Int

    func body(content: Content) -> some View {
        if count < 1 {
            content
        } else {
            content
                .overlay(MyBadge(count: count))
        }
    }
}

extension View {
    func myBadge(count: Int) -> some View {
        modifier(MyBadgeModifier(count: count))
    }
}
