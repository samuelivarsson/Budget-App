//
//  IntentHandler.swift
//  BudgetWidgetIntentExtension
//
//  Created by Samuel Ivarsson on 2023-03-30.
//

import Firebase
import Intents

class IntentHandler: INExtension, SelectAccountIntentHandling {
    func resolveAccount(for intent: SelectAccountIntent, with completion: @escaping (BalanceAccountResolutionResult) -> Void) {}
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        return self
    }
    
    func provideAccountOptionsCollection(for intent: SelectAccountIntent, with completion: @escaping (INObjectCollection<BalanceAccount>?, Error?) -> Void) {
        FirebaseApp.configure()
        do {
            try Auth.auth().useUserAccessGroup("\(Utility.teamId).com.samuelivarsson.Budget")
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        // Ensure user is logged in
        guard let currentUser = Auth.auth().currentUser else {
            completion(nil, UserError.notLoggedIn)
            return
        }
        
        let db = Firestore.firestore()
        db.collection("Users").document(currentUser.uid).getDocument { snapshot, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let document = snapshot else {
                completion(nil, FirestoreError.documentNotExist)
                return
            }
            
            // Success
            do {
                let user = try document.data(as: User.self)
                
                let balanceAccounts: [BalanceAccount] = user.quickBalanceAccounts.map { quickBalanceAccount in
                    let balanceAccount = BalanceAccount(identifier: quickBalanceAccount.budgetAccountId, display: quickBalanceAccount.name)
                    balanceAccount.name = quickBalanceAccount.name
                    balanceAccount.subscriptionId = quickBalanceAccount.subscriptionId
                    balanceAccount.budgetAccountId = quickBalanceAccount.budgetAccountId
                    return balanceAccount
                }
                
                // Create a collection with the array of characters.
                let collection = INObjectCollection(items: balanceAccounts)

                // Call the completion handler, passing the collection.
                completion(collection, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
}
