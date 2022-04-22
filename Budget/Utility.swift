//
//  Utility.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-15.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseCore

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
    
    static func uploadProfilePicture(image: Image) {
        
    }
}

/// Create a color with hex-code
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

// Make background colors easily accessible
//extension Color {
//
//}

/// A generic view that shows images from the network.
struct NetworkImage: View {
    @EnvironmentObject private var errorHandling: ErrorHandling
    let url: URL?
    let failImage: Image
    var fit = true
    
    var body: some View {
        if let url = url, let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
            if fit {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(uiImage: uiImage)
                    .onAppear {
                        print(uiImage.size)
                    }
            }
        } else {
            if fit {
                failImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .onAppear {
                        errorHandling.handle(error: NetworkError.imageFetch)
                    }
            } else {
                failImage
                    .onAppear {
                        errorHandling.handle(error: NetworkError.imageFetch)
                    }
            }
        }
    }
}

/// A generic view that shows a users profile picture.
struct UserPicture: View {
    @EnvironmentObject private var errorHandling: ErrorHandling
    let user: User?
    var failImage = Image(systemName: "person.circle")
    var fit = true
    
    var body: some View {
        if let user = user {
            if !user.isAnonymous {
                NetworkImage(url: user.photoURL, failImage: failImage, fit: fit)
            } else {
                if fit {
                    failImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    failImage
                }
            }
        } else {
            if fit {
                failImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
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

/// View for picking an image from the user's photolibrary
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
 
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
 
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
 
        return imagePicker
    }
 
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
 
    }
}
