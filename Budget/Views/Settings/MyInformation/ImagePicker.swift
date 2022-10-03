//
//  ImagePicker.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-29.
//

import Foundation
import UIKit
import SwiftUI

/// View for picking an image from the user's photolibrary
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var storageViewModel: StorageViewModel
    
    @Binding var selectedImage: UIImage
    
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
 
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
 
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator
 
        return imagePicker
    }
 
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
 
    }
    
    func uploadPicture() {
        Utility.uploadMedia(image: selectedImage) { url, error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            if let url = url {
                self.storageViewModel.changeProfilePicture(url: url) { error in
                    if let error = error {
                        self.errorHandling.handle(error: error)
                        return
                    }
                    
                    // Success
                }
            }
        }
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
     
        var parent: ImagePicker
     
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
     
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
                parent.selectedImage = image
            }
            
            else if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                parent.selectedImage = image
            }
     
            parent.uploadPicture()
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
