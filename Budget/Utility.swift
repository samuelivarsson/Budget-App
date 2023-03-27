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
    
    static var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        return dateFormatter
    }

    static var dateFormatterNoTime: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter
    }
    
    static func convertToDouble(_ amountString: String) -> Double? {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        
        if let number = formatter.number(from: amountString) {
            return number.doubleValue
        } else {
            return nil
        }
    }

    static func dateToString(date: Date) -> String {
        return dateFormatter.string(from: date)
    }

    static func dateToString(date: Date, size: DateFormatter.Style) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = size
        dateFormatter.timeStyle = size
        return dateFormatter.string(from: date)
    }

    static func dateToStringNoTime(date: Date) -> String {
        return dateFormatterNoTime.string(from: date)
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
        guard let result: String = currencyFormatter.string(from: value as NSNumber) else {
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
    static func getBudgetPeriod(date: Date = Date(), monthsBack: Int = 0, monthStartsOn: Int) -> (Date, Date) {
        let calendar = Calendar.current
        let referenceDate = calendar.date(byAdding: .month, value: -monthsBack, to: date) ?? Date()

        var dayComponent = DateComponents()
        dayComponent.day = monthStartsOn
        
        let toDate = calendar.nextDate(
            after: referenceDate,
            matching: dayComponent,
            matchingPolicy: .nextTime,
            repeatedTimePolicy: .first,
            direction: .forward
        ) ?? Date()

        let fromDate = calendar.date(byAdding: .month, value: -1, to: toDate) ?? Date()

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
    
    static func getSwishUrl(amount: Double, friend: User) -> URL? {
        let amountTwoDecimals = Utility.doubleToTwoDecimals(value: abs(amount))
        // TODO: - Fix to reflect date of transaction after last swish
        let date = dateToStringNoTime(date: Date())
        let info = "squaringUpTransactionsSince".localizeString() + " " + date
        let data =
            "{" +
            "\"amount\":{" +
            "\"value\":\(amountTwoDecimals)" +
            "}," +
            "\"message\":{" +
            "\"value\":\"\(info)\"" +
            "}," +
            "\"payee\":{" +
            "\"value\":\"\(friend.phone)\"" +
            "}," +
            "\"version\":1" +
            "}"
        
        let callbackUrl = "budgetapp%3A%2F%2F?sourceApplication=swish%26userId=\(friend.id)"
        
        let queryItems = [URLQueryItem(name: "callbackurl", value: callbackUrl), URLQueryItem(name: "data", value: data)]
        var urlComps = URLComponents(string: "swish://payment") ?? .init()
        urlComps.queryItems = queryItems
        return urlComps.url
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

struct MyBadge: View {
    let count: Int

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear
            Text(String(count))
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(5)
                .background(Color.red)
                .clipShape(Circle())
                // custom positioning in the top-right corner
                .alignmentGuide(.top) { $0[.bottom] - $0.height * 0.25 }
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
