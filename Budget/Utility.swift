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
    static var listeners: [ListenerRegistration] = .init()
    
    static var firstLoadFinished = false

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
        return self.dateFormatter.string(from: date)
    }

    static func dateToString(date: Date, style: DateFormatter.Style, timeStyle: DateFormatter.Style? = nil) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = style
        if let timeStyle = timeStyle {
            dateFormatter.timeStyle = timeStyle
        } else {
            dateFormatter.timeStyle = style
        }
        return dateFormatter.string(from: date)
    }

    static func stringToDate(string: String, style: DateFormatter.Style, timeStyle: DateFormatter.Style? = nil) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = style
        if let timeStyle = timeStyle {
            dateFormatter.timeStyle = timeStyle
        } else {
            dateFormatter.timeStyle = style
        }
        return dateFormatter.date(from: string)
    }

    static func dateToStringNoTime(date: Date) -> String {
        return self.dateFormatterNoTime.string(from: date)
    }

    static func removeListener(listener: ListenerRegistration?) {
        guard let listener = listener else {
            return
        }
        var index = -1
        for i in 0..<self.listeners.count {
            if self.listeners[i].isEqual(listener) {
                self.listeners[i].remove()
                index = i
            }
        }
        if index >= 0, index < self.listeners.count {
            self.listeners.remove(at: index)
        }
    }

    static func removeListeners() {
        for i in 0..<self.listeners.count {
            self.listeners[i].remove()
        }
        self.listeners = .init()
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
            self.getImageFromURL(url: url) { uiImage, error in
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

    static func getSwishUrl(amount: Double, friendId: String, friendPhone: String, info: String) -> URL? {
        let amountTwoDecimals = Utility.doubleToTwoDecimals(value: abs(amount))
        var newInfo = info
        if info.count > 50 {
            newInfo = String(newInfo.prefix(46))
            newInfo.append("...")
        }
        let data =
            "{" +
            "\"amount\":{" +
            "\"value\":\(amountTwoDecimals)" +
            "}," +
            "\"message\":{" +
            "\"value\":\"\(newInfo)\"" +
            "}," +
            "\"payee\":{" +
            "\"value\":\"\(friendPhone)\"" +
            "}," +
            "\"version\":1" +
            "}"

        let callbackUrl = "budgetapp%3A%2F%2F?sourceApplication=swish%26userId=\(friendId)%26amount=\(amountTwoDecimals)"

        let queryItems = [URLQueryItem(name: "callbackurl", value: callbackUrl), URLQueryItem(name: "data", value: data)]
        var urlComps = URLComponents(string: "swish://payment") ?? .init()
        urlComps.queryItems = queryItems
        return urlComps.url
    }
    
    static func setAmountPerParticipant(splitOption: SplitOption, participants: Binding<[Participant]>, totalAmount: Double, hasWritten: [String], myUserId: String) -> String? {
        switch splitOption {
        case .standard:
            var nonManualParticipantsCount: Double = 0
            var manualParticipantsTotalAmount: Double = 0
            for participant in participants.wrappedValue {
                if hasWritten.contains(participant.userId) {
                    manualParticipantsTotalAmount += participant.amount
                } else {
                    nonManualParticipantsCount += 1
                }
            }
            
            let totalAmountLeft = totalAmount - manualParticipantsTotalAmount
            let amountPerParticipant = Utility.doubleToTwoDecimalsFloored(value: totalAmountLeft / nonManualParticipantsCount)
            var val = totalAmountLeft
            
            guard let firstNonManualIndex = self.getFirstNonManualIndex(participants: participants, hasWritten: hasWritten) else {
                return nil
            }
            
            for i in (0 ..< participants.wrappedValue.count).reversed() {
                if !hasWritten.contains(participants.wrappedValue[i].userId) {
                    participants.wrappedValue[i].amount = Utility.doubleToTwoDecimals(value: i == firstNonManualIndex ? val : amountPerParticipant)
                    val -= amountPerParticipant
                }
            }
            
            return nil
            
        case .meEverything:
            for i in 0..<participants.wrappedValue.count {
                if participants.wrappedValue[i].userId == myUserId {
                    participants.wrappedValue[i].amount = Utility.doubleToTwoDecimals(value: totalAmount)
                } else {
                    participants.wrappedValue[i].amount = 0
                }
            }
            return nil
            
        case .heSheEverything:
            for i in 0..<participants.wrappedValue.count {
                if participants.wrappedValue[i].userId != myUserId {
                    participants.wrappedValue[i].amount = Utility.doubleToTwoDecimals(value: totalAmount)
                } else {
                    participants.wrappedValue[i].amount = 0
                }
            }
            return nil

        case .ownItems:
            return nil
        }
    }
    
    private static func getFirstNonManualIndex(participants: Binding<[Participant]>, hasWritten: [String]) -> Int? {
        for i in 0 ..< participants.wrappedValue.count {
            if !hasWritten.contains(participants.wrappedValue[i].userId) {
                return i
            }
        }
        return nil
    }
    
    static func getTransactionAction(transaction: Transaction, userId: String, role: UserRole) -> TransactionAction {
        if role == .superAdmin {
            return .edit
        }
        
        return transaction.isMine(userId: userId) ? .edit : .view
    }
}

/// A view that shows an optional UIImage, if nil, its shows the failImage.
struct ProfilePicture: View {
    let uiImage: UIImage?
    let failImage: Image
    let fill: Bool = true

    var body: some View {
        if let uiImage = uiImage {
            if self.fill {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(uiImage: uiImage)
            }
        } else {
            if self.fill {
                self.failImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                self.failImage
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
            Image(systemName: self.imgName).foregroundColor(.secondary)
            TextField(self.placeHolderText, text: self.$text)
                .keyboardType(self.keyboardType)
                .disableAutocorrection(self.disableAutocorrection)
                .textInputAutocapitalization(self.autoCapitalization)
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
            if self.showPassword {
                TextField("password", text: self.$password)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.none)
            } else {
                SecureField("password", text: self.$password)
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
            if self.didLoad == false {
                self.didLoad = true
                self.action?()
            }
        }
    }
}

struct MyBadge: View {
    let count: Int

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear
            Text(String(self.count))
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
        if self.count < 1 {
            content
        } else {
            content
                .overlay(MyBadge(count: self.count))
        }
    }
}
