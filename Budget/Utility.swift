//
//  Utility.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-15.
//

import Foundation
import SwiftUI
import FirebaseAuth

/// Offers useful utilities
class Utility {
    static func doubleToLocalCurrency(value: Double) -> String {
        let currencyFormatter: NumberFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale.current
        guard let result: String = currencyFormatter.string(from: value as NSNumber) else {
            return "Error when formatting to local currency"
        }
        return result
    }
}

/// Create a color with hex-code
extension Color {
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
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

/// A generic view that shows a users profile picture.
struct UserPicture: View {
    let user: User?
    let failImage = Image(systemName: "person.circle")
    
    var body: some View {
        if let user = user {
            NetworkImage(url: user.photoURL, failImage: failImage)
        } else {
            failImage
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}

/// A generic view that shows images from the network.
struct NetworkImage: View {
    let url: URL?
    let failImage: Image
    
    var body: some View {
        if let url = url,
           let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            failImage
                .resizable()
                .aspectRatio(contentMode: .fit)
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
