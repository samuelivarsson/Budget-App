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
    
    private func isNowDateAfterOrSameDayAsDate(monthStartsOn: Int, nowDate: Date = Date.now, date: Date) -> Bool {
        let dayComponent = Calendar.current.dateComponents([.day], from: date)
        if let day = dayComponent.day {
            return isNowDateAfterOrSameDay(monthStartsOn: monthStartsOn, nowDate: nowDate, day: day)
        }
        return true
    }
    
    private func isNowDateAfterOrSameDay(monthStartsOn: Int, nowDate: Date = Date.now, day: Int) -> Bool {
        let currentDayComponent = Calendar.current.dateComponents([.day], from: nowDate)
        if let currentDay = currentDayComponent.day {
            return (monthStartsOn <= day && day <= currentDay) || (day <= currentDay && currentDay < monthStartsOn) || (currentDay < monthStartsOn && monthStartsOn <= day)
        }
        return true
    }
    
    private func isAfterOrSameDayAsPayDate(monthStartsOn: Int, nowDate: Date = Date.now) -> Bool {
        return isNowDateAfterOrSameDay(monthStartsOn: monthStartsOn, nowDate: nowDate, day: self.getDayOfPay(nowDate: nowDate))
    }
    
    private func getMonthsSinceLastPay(monthStartsOn: Int, date: Date = Date()) -> Int {
        if self.months == 1 {
            return 1
        }
        let fromDate = Utility.getBudgetPeriod(date: self.startDate, monthStartsOn: monthStartsOn).0
        let toDate = Utility.getBudgetPeriod(date: date, monthStartsOn: monthStartsOn).0
        let diff = Calendar.current.dateComponents([.month], from: fromDate, to: toDate)
        return (diff.month ?? 0) + (diff.year ?? 0) * 12
    }
    
    private func getAmountMultiplier(monthStartsOn: Int, date: Date = Date()) -> Int {
        if self.months == 1 {
            return 1
        }
        
        if self.isPayMonth(monthStartsOn: monthStartsOn, date: date) && !self.isAfterOrSameDayAsPayDate(monthStartsOn: monthStartsOn, nowDate: date) {
            return self.months
        }
        
        return self.getMonthsSinceLastPay(monthStartsOn: monthStartsOn, date: date) % self.months
    }
    
    private func isPayMonth(monthStartsOn: Int, date: Date = Date()) -> Bool {
        if self.months == 1 {
            return true
        }
        return (self.getMonthsSinceLastPay(monthStartsOn: monthStartsOn, date: date) % self.months) == 0
    }
    
    func isPaid(monthStartsOn: Int, nowDate: Date = Date.now) -> Bool {
        return self.isAfterOrSameDayAsPayDate(monthStartsOn: monthStartsOn, nowDate: nowDate) && self.isPayMonth(monthStartsOn: monthStartsOn, date: nowDate)
    }
    
    private func getTemporaryExtraFromShare(monthStartsOn: Int, nowDate: Date = Date.now) -> Double {
        if !self.share {
            return 0
        }
        if self.isPayMonth(monthStartsOn: monthStartsOn, date: nowDate) {
            if self.imPaying && !self.isAfterOrSameDayAsPayDate(monthStartsOn: monthStartsOn, nowDate: nowDate) {
                return self.isNowDateAfterOrSameDay(monthStartsOn: monthStartsOn, nowDate: nowDate, day: self.receiveDay) ? self.amount / 2 : 0
            }
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
            total += self.getShareOfAmount(monthStartsOn: monthStartsOn, monthsBack: i, nowDate: nowDate)
        }
        total += self.getTemporaryExtraFromShare(monthStartsOn: monthStartsOn, nowDate: nowDate)
        return total
    }
}
