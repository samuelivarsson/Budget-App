//
//  FriendsViewModel.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-05-03.
//

import Foundation
import SwiftUI
import FirebaseStorage

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var friendPictures: [String: UIImage] = [:]
    @Published var usersWithNoPicture: [String] = []
    
    private var inFlight: [String: [(UIImage?, Error?) -> Void]] = [:]
    private let pictureQueue = DispatchQueue(label: "picture-loader")
    
    func hasNoPicture(uid: String) -> Bool {
        return self.usersWithNoPicture.contains(uid)
    }
    
    func getPicture(uid: String, completion: @escaping (UIImage?, Error?) -> Void) {
        // 1. Return cached or no-picture info
        if hasNoPicture(uid: uid) {
            completion(nil, nil)
            return
        }

        if let image = friendPictures[uid] {
            completion(image, nil)
            return
        }

        // 2. If request already in-flight, append completion
        if inFlight[uid] != nil {
            print("appending...")
            inFlight[uid]?.append(completion)
            return
        }

        // 3. Start new request
        inFlight[uid] = [completion]

        Utility.getProfilePictureFromUID(uid: uid) { [weak self] image, error in
            guard let self = self else { return }
            
            print("fetching...")

            Task { @MainActor in
                // All code inside here runs on main thread, safe for @Published
                let completions = self.inFlight[uid] ?? []
                self.inFlight[uid] = nil

                if let error = error {
                    let nsError = error as NSError
                    let code = StorageErrorCode(rawValue: nsError.code)

                    switch code {
                    case .objectNotFound:
                        print("The user has no picture")
                        self.usersWithNoPicture.append(uid)
                        completions.forEach { $0(nil, nil) }
                    default:
                        completions.forEach { $0(nil, error) }
                    }
                    return
                }

                guard let image = image else {
                    let info = "Found nil when extracting image in onLoad in FriendDetailView"
                    print(info)
                    completions.forEach { $0(nil, ApplicationError.unexpectedNil(info)) }
                    return
                }

                self.friendPictures[uid] = image
                completions.forEach {
                    print("Completing for \(String(describing: $0))")
                    $0(image, nil)
                }
            }
        }
    }
}
