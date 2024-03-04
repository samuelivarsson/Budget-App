//
//  Math.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2024-03-03.
//

import Foundation

class Math {
    static func evaluateExpression(_ expression: String) -> Double? {
        if expression.isEmpty {
            return nil
        }
        
        var result: Double?
        
        do {
            try ObjC.catchException {
                let mathExpression = NSExpression(format: expression)
            
                result = mathExpression.expressionValue(with: nil, context: nil) as? Double
            }
        } catch {
            print("An error ocurred: \(error)")
        }
        
        return result
    }
}
