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
    var lastDay: Bool = false
    var months: Int = 1
    var startDate: Date = Date.now
    var share: Bool = false
    var imPaying: Bool = true
    var receiveDay: Int = 27
    
    static func getDummyOverhead() -> Overhead {
        return Overhead(name: "", amount: 0, dayOfPay: 27)
    }
    
    func getShareOfAmount(monthStartsOn: Int) -> Double {
        let share: Double = self.share ? 2 : 1
        let shareOfAmount: Double = (self.amount / share) / Double(self.months)
        let roundedToTwoDecimals: Double = round(shareOfAmount * 100) / 100
        let remainingToPay = self.amount / share - roundedToTwoDecimals * Double(self.months - 1)
        return self.isPayMonth(monthStartsOn: monthStartsOn) ? remainingToPay : roundedToTwoDecimals
    }
    
    func getDayOfPay() -> Int {
        return self.lastDay ? Date.now.endOfMonth().get(.day) : self.dayOfPay
    }
    
    private func isAfterPayDate(monthStartsOn: Int) -> Bool {
        let dayComponent = Calendar.current.dateComponents([.day], from: Date.now)
        if let currentDay = dayComponent.day {
            return (monthStartsOn <= self.getDayOfPay() && self.getDayOfPay() <= currentDay) || (self.getDayOfPay() <= currentDay && currentDay < monthStartsOn) || (currentDay < monthStartsOn && monthStartsOn <= self.getDayOfPay())
        }
        return true
    }
    
    private func getMonthsSinceLastPay(monthStartsOn: Int) -> Int {
        let fromDate = Utility.getBudgetPeriod(date: self.startDate, monthStartsOn: monthStartsOn).0
        let toDate = Utility.getBudgetPeriod(monthStartsOn: monthStartsOn).0
        return Calendar.current.dateComponents([.month], from: fromDate, to: toDate).month ?? 0
    }
    
    private func getAmountMultiplier(monthStartsOn: Int) -> Double {
        return self.months < 2 ? 1 : Double(self.getMonthsSinceLastPay(monthStartsOn: monthStartsOn) % self.months)
    }
    
    private func isPayMonth(monthStartsOn: Int) -> Bool {
        if self.months < 2 {
            return true
        }
        return self.getAmountMultiplier(monthStartsOn: monthStartsOn) == 0
    }
    
    func isPaid(monthStartsOn: Int) -> Bool {
        return self.isAfterPayDate(monthStartsOn: monthStartsOn) && self.isPayMonth(monthStartsOn: monthStartsOn)
    }
    
    private func getTemporaryExtraFromShare(monthStartsOn: Int) -> Double {
        if !self.share {
            return 0
        }
        let dayComponent = Calendar.current.dateComponents([.day], from: Date.now)
        if let currentDay = dayComponent.day {
            return self.isPayMonth(monthStartsOn: monthStartsOn) && self.receiveDay <= currentDay ? self.amount / 2 : 0
        }
        return 0
    }
    
    func getTemporaryBalanceOnAccount(monthStartsOn: Int) -> Double {
        if self.isPaid(monthStartsOn: monthStartsOn) {
            return 0
        }
        var total: Double = 0
        let monthsSinceLastPay = self.getMonthsSinceLastPay(monthStartsOn: monthStartsOn)
        for _ in 0..<monthsSinceLastPay {
            total += self.getShareOfAmount(monthStartsOn: monthStartsOn)
        }
        total += self.getTemporaryExtraFromShare(monthStartsOn: monthStartsOn)
        return total
    }
}
