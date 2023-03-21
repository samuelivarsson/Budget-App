//
//  Overhead.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-04.
//

import Foundation

struct Overhead: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var amount: Double
    var dayOfPay: Int
    var months: Int = 1
    var startDate: Date = Date.now
    var share: Bool = false
    
    static func getDummyOverhead() -> Overhead {
        return Overhead(name: "", amount: 0, dayOfPay: 27)
    }
    
    func getMyAmount() -> Double {
        let share: Double = self.share ? 2 : 1
        return (self.amount / share) / Double(self.months)
    }
    
    private func isAfterPayDate(monthStartsOn: Int) -> Bool {
        let dayComponent = Calendar.current.dateComponents([.day], from: Date.now)
        if let currentDay = dayComponent.day {
            return (monthStartsOn <= self.dayOfPay && self.dayOfPay <= currentDay) || (self.dayOfPay <= currentDay && currentDay < monthStartsOn) || (currentDay < monthStartsOn && monthStartsOn <= self.dayOfPay)
        }
        return true
    }
    
    func getMonthsSinceLastPay(monthStartsOn: Int) -> Int {
        let fromDate = Utility.getBudgetPeriod(date: self.startDate, monthStartsOn: monthStartsOn).0
//        print("\(self.name) - fromDate: \(fromDate)")
        let toDate = Utility.getBudgetPeriod(monthStartsOn: monthStartsOn).0
//        print("\(self.name) - toDate: \(toDate)")
        return Calendar.current.dateComponents([.month], from: fromDate, to: toDate).month ?? 0
    }
    
    private func isPayMonth(monthStartsOn: Int) -> Bool {
//        print("\(self.name) - monthsSinceLastPay: \(self.getMonthsSinceLastPay(monthStartsOn: monthStartsOn))")
        // TODO: - Fix bug where overheads that start on the 25th gets wrong dates.
        return (self.getMonthsSinceLastPay(monthStartsOn: monthStartsOn) % self.months) == 0
    }
    
    func isPaid(monthStartsOn: Int) -> Bool {
        return self.isAfterPayDate(monthStartsOn: monthStartsOn) && self.isPayMonth(monthStartsOn: monthStartsOn)
    }
}
