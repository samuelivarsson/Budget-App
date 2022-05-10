//
//  FriendsViewModel.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-05-03.
//

import Foundation
import SwiftUI

class FriendsViewModel: ObservableObject {
    @Published var friendPictures: [String: UIImage] = [:]
}
