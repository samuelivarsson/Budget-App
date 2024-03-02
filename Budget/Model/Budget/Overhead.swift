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
    
    func getShareOfAmount(monthStartsOn: Int, monthsBack: Int = 0, nowDate: Date = Date.now) -> Double {
        let share: Double = self.share ? 2 : 1
        let shareOfAmount: Double = (self.amount / share) / Double(self.months)
        let roundedToTwoDecimals: Double = round(shareOfAmount * 100) / 100
        let remainingToPay = self.amount / share - roundedToTwoDecimals * Double(self.months - 1)
        let date = Calendar.current.date(byAdding: .month, value: -monthsBack, to: nowDate) ?? Date()
        return self.isPayMonth(monthStartsOn: monthStartsOn, date: date) ? remainingToPay : roundedToTwoDecimals
    }
    
    func getDayOfPay(nowDate: Date = Date.now) -> Int {
        return self.lastDay ? nowDate.endOfMonth().get(.day) : self.dayOfPay
    }
    
    private func isAfterPayDate(monthStartsOn: Int, nowDate: Date = Date.now) -> Bool {
        let dayComponent = Calendar.current.dateComponents([.day], from: nowDate)
        if let currentDay = dayComponent.day {
            return (monthStartsOn <= self.getDayOfPay() && self.getDayOfPay() <= currentDay) || (self.getDayOfPay() <= currentDay && currentDay < monthStartsOn) || (currentDay < monthStartsOn && monthStartsOn <= self.getDayOfPay())
        }
        return true
    }
    
    private func getMonthsSinceLastPay(monthStartsOn: Int, date: Date = Date()) -> Int {
        if self.months == 1 {
            return 1
        }
        let fromDate = Utility.getBudgetPeriod(date: self.startDate, monthStartsOn: monthStartsOn).0
        let toDate = Utility.getBudgetPeriod(date: date, monthStartsOn: monthStartsOn).0
//        print(self.name)
//        print(Calendar.current.dateComponents([.month], from: fromDate, to: toDate).month ?? 0)
        return Calendar.current.dateComponents([.month], from: fromDate, to: toDate).month ?? 0
    }
    
    private func getAmountMultiplier(monthStartsOn: Int, date: Date = Date()) -> Int {
        return self.months < 2 ? 1 : self.getMonthsSinceLastPay(monthStartsOn: monthStartsOn, date: date) % (self.months + 1)
    }
    
    private func isPayMonth(monthStartsOn: Int, date: Date = Date()) -> Bool {
        if self.months < 2 {
            return true
        }
        return self.getAmountMultiplier(monthStartsOn: monthStartsOn, date: date) == self.months
    }
    
    func isPaid(monthStartsOn: Int, nowDate: Date = Date.now) -> Bool {
        return self.isAfterPayDate(monthStartsOn: monthStartsOn, nowDate: nowDate) && self.isPayMonth(monthStartsOn: monthStartsOn, date: nowDate)
    }
    
    private func getTemporaryExtraFromShare(monthStartsOn: Int, nowDate: Date = Date.now) -> Double {
        if !self.share {
            return 0
        }
        let dayComponent = Calendar.current.dateComponents([.day], from: nowDate)
        if let currentDay = dayComponent.day {
            return self.isPayMonth(monthStartsOn: monthStartsOn) && self.receiveDay <= currentDay ? self.amount / 2 : 0
        }
        return 0
    }
    
    func getTemporaryBalanceOnAccount(monthStartsOn: Int, nowDate: Date = Date.now) -> Double {
        if self.isPaid(monthStartsOn: monthStartsOn, nowDate: nowDate) {
            return 0
        }
        var total: Double = 0
        let monthsSinceLastPay = self.getAmountMultiplier(monthStartsOn: monthStartsOn, date: nowDate)
        for i in 0..<monthsSinceLastPay {
            total += self.getShareOfAmount(monthStartsOn: monthStartsOn, monthsBack: i)
        }
        total += self.getTemporaryExtraFromShare(monthStartsOn: monthStartsOn)
        return total
    }
}
