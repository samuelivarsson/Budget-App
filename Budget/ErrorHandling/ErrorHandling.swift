//
//  ErrorHandling.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-18.
//

import Firebase
import FirebaseAuth
import FirebaseCore
import Foundation
import GoogleSignIn
import SwiftUI

struct ErrorAlert: Identifiable {
    var id = UUID()
    var message: String
    var reason: String?
    var recovery: String?
    var dismissAction: (() -> Void)?
}

class ErrorHandling: ObservableObject {
    @Published var currentAlert: ErrorAlert?
    @Published var showError: Bool = false
    private var currentTask: DispatchWorkItem?

    func handle(error: Error, duration: TimeInterval = 8) {
        DispatchQueue.main.async {
            let nsError = error as NSError
            print(nsError.localizedDescription)
            self.currentAlert = ErrorAlert(
                message: nsError.localizedDescription,
                reason: nsError.localizedFailureReason,
                recovery: nsError.localizedRecoverySuggestion,
                dismissAction: self.dismissError
            )
            self.animateAndDelayWithSeconds(0, showError: true)
            self.currentTask = self.animateAndDelayWithSeconds(duration, showError: false)
        }
    }

    func dismissError() {
        animateAndDelayWithSeconds(0, showError: false)
        guard let currentTask = currentTask else { return }
        currentTask.cancel()
        self.currentTask = nil
    }

    @discardableResult
    private func animateAndDelayWithSeconds(_ seconds: TimeInterval, showError: Bool) -> DispatchWorkItem {
        let task = DispatchWorkItem { [weak self] in
            withAnimation {
                guard let self = self else { return }
                self.showError = showError
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: task)

        return task
    }
}

struct HandleErrorsByShowingBoxOnTopViewModifier: ViewModifier {
    @StateObject var errorHandling = ErrorHandling()

    private var errorLabel: some View {
        Button {
            if let currentAlert = errorHandling.currentAlert {
                if let dismissAction = currentAlert.dismissAction {
                    dismissAction()
                }
            }
        } label: {
            HStack {
                Spacer()
                VStack(spacing: 5) {
                    if let currentAlert = errorHandling.currentAlert {
                        Text("error")
                            .fontWeight(.bold)
                            .foregroundColor(Color.white)
                        if let reason = currentAlert.reason, let recovery = currentAlert.recovery {
                            Text("\(currentAlert.message). \(reason). \(recovery)")
                                .foregroundColor(Color.white)
                                .lineLimit(2)
                                .allowsTightening(true)
                                .minimumScaleFactor(0.5)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 10)
                                .padding(.bottom, 10)
                        } else {
                            Text("\(currentAlert.message).")
                                .foregroundColor(Color.white)
                                .lineLimit(2)
                                .allowsTightening(true)
                                .minimumScaleFactor(0.5)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 10)
                                .padding(.bottom, 10)
                        }
                    }
                }
                Spacer()
            }
            .background(Color.red)
        }
        .buttonStyle(.plain)
    }

    func body(content: Content) -> some View {
        ZStack {
            content
                .environmentObject(errorHandling)
            VStack {
                if errorHandling.showError {
                    errorLabel.transition(.asymmetric(insertion: .fadeAndSlide, removal: .fadeAndSlide))
                    Spacer()
                }
            }
        }
    }
}
