//
//  OverheadTests.swift
//  BudgetTests
//
//  Created by Samuel Ivarsson on 2024-03-02.
//

import XCTest

final class OverheadTests: XCTestCase {
    var dateComponents: DateComponents = DateComponents()
    var startDate: Date = Date.now
    var nowDate: Date = Date.now

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        dateComponents.hour = 8
        
        dateComponents.year = 2024
        dateComponents.month = 1
        dateComponents.day = 2
        startDate = Calendar.current.date(from: dateComponents) ?? Date.now
        print(startDate)
        
        dateComponents.year = 2024
        dateComponents.month = 2
        dateComponents.day = 27
        nowDate = Calendar.current.date(from: dateComponents) ?? Date.now
        print(nowDate)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testOverheadPaidInTwoMonths() throws {
        dateComponents.year = 2024
        dateComponents.month = 1
        dateComponents.day = 23
        nowDate = Calendar.current.date(from: dateComponents) ?? Date.now
        print(nowDate)
        
        let overhead = Overhead(
            name: "Test1",
            amount: 280,
            dayOfPay: 28,
            lastDay: false,
            months: 2,
            startDate: startDate,
            share: false,
            imPaying: false,
            receiveDay: 27
        )
        let temporaryBalance = overhead.getTemporaryBalanceOnAccount(monthStartsOn: 25, nowDate: nowDate)
        XCTAssertEqual(0, temporaryBalance)
    }
    
    func testOverheadPaidNextMonth1() throws {
        dateComponents.year = 2024
        dateComponents.month = 1
        dateComponents.day = 25
        nowDate = Calendar.current.date(from: dateComponents) ?? Date.now
        print(nowDate)
        
        let overhead = Overhead(
            name: "Test1",
            amount: 280,
            dayOfPay: 28,
            lastDay: false,
            months: 2,
            startDate: startDate,
            share: false,
            imPaying: false,
            receiveDay: 27
        )
        let temporaryBalance = overhead.getTemporaryBalanceOnAccount(monthStartsOn: 25, nowDate: nowDate)
        XCTAssertEqual(140, temporaryBalance)
    }
    
    func testOverheadPaidNextMonth2() throws {
        dateComponents.year = 2024
        dateComponents.month = 2
        dateComponents.day = 1
        nowDate = Calendar.current.date(from: dateComponents) ?? Date.now
        print(nowDate)
        
        let overhead = Overhead(
            name: "Test1",
            amount: 280,
            dayOfPay: 28,
            lastDay: false,
            months: 2,
            startDate: startDate,
            share: false,
            imPaying: false,
            receiveDay: 27
        )
        let temporaryBalance = overhead.getTemporaryBalanceOnAccount(monthStartsOn: 25, nowDate: nowDate)
        XCTAssertEqual(140, temporaryBalance)
    }
    
    func testOverheadPaidTomorrow() throws {
        let overhead = Overhead(
            name: "Test1",
            amount: 280,
            dayOfPay: 28,
            lastDay: false,
            months: 2,
            startDate: startDate,
            share: false,
            imPaying: false,
            receiveDay: 27
        )
        let temporaryBalance = overhead.getTemporaryBalanceOnAccount(monthStartsOn: 25, nowDate: nowDate)
        XCTAssertEqual(280, temporaryBalance)
    }

    func testOverheadPaidToday() throws {
        let overhead = Overhead(
            name: "Test1",
            amount: 280,
            dayOfPay: 27,
            lastDay: false,
            months: 2,
            startDate: startDate,
            share: false,
            imPaying: false,
            receiveDay: 27
        )
        let temporaryBalance = overhead.getTemporaryBalanceOnAccount(monthStartsOn: 25, nowDate: nowDate)
        XCTAssertEqual(0, temporaryBalance)
    }
    
    func testOverheadPaidYesterday() throws {
        let overhead = Overhead(
            name: "Test1",
            amount: 280,
            dayOfPay: 26,
            lastDay: false,
            months: 2,
            startDate: startDate,
            share: false,
            imPaying: false,
            receiveDay: 27
        )
        let temporaryBalance = overhead.getTemporaryBalanceOnAccount(monthStartsOn: 25, nowDate: nowDate)
        XCTAssertEqual(0, temporaryBalance)
    }
    
    func testOverheadPaidLastMonth() throws {
        dateComponents.year = 2024
        dateComponents.month = 3
        dateComponents.day = 2
        nowDate = Calendar.current.date(from: dateComponents) ?? Date.now
        print(nowDate)
        
        let overhead = Overhead(
            name: "Test1",
            amount: 280,
            dayOfPay: 27,
            lastDay: false,
            months: 2,
            startDate: startDate,
            share: false,
            imPaying: false,
            receiveDay: 27
        )
        let temporaryBalance = overhead.getTemporaryBalanceOnAccount(monthStartsOn: 25, nowDate: nowDate)
        XCTAssertEqual(0, temporaryBalance)
    }
    
    // ------------------------------- SHARE -------------------------------

    func testOverheadPaidInTwoMonthsShare() throws {
        dateComponents.year = 2024
        dateComponents.month = 1
        dateComponents.day = 23
        nowDate = Calendar.current.date(from: dateComponents) ?? Date.now
        print(nowDate)
        
        let overhead = Overhead(
            name: "Test1",
            amount: 280,
            dayOfPay: 28,
            lastDay: false,
            months: 2,
            startDate: startDate,
            share: true,
            imPaying: false,
            receiveDay: 27
        )
        let temporaryBalance = overhead.getTemporaryBalanceOnAccount(monthStartsOn: 25, nowDate: nowDate)
        XCTAssertEqual(0, temporaryBalance)
    }
    
    func testOverheadPaidNextMonthShare1() throws {
        dateComponents.year = 2024
        dateComponents.month = 1
        dateComponents.day = 25
        nowDate = Calendar.current.date(from: dateComponents) ?? Date.now
        print(nowDate)
        
        let overhead = Overhead(
            name: "Test1",
            amount: 280,
            dayOfPay: 28,
            lastDay: false,
            months: 2,
            startDate: startDate,
            share: true,
            imPaying: false,
            receiveDay: 27
        )
        let temporaryBalance = overhead.getTemporaryBalanceOnAccount(monthStartsOn: 25, nowDate: nowDate)
        XCTAssertEqual(70, temporaryBalance)
    }
    
    func testOverheadPaidNextMonthShare2() throws {
        dateComponents.year = 2024
        dateComponents.month = 2
        dateComponents.day = 1
        nowDate = Calendar.current.date(from: dateComponents) ?? Date.now
        print(nowDate)
        
        let overhead = Overhead(
            name: "Test1",
            amount: 280,
            dayOfPay: 28,
            lastDay: false,
            months: 2,
            startDate: startDate,
            share: true,
            imPaying: false,
            receiveDay: 27
        )
        let temporaryBalance = overhead.getTemporaryBalanceOnAccount(monthStartsOn: 25, nowDate: nowDate)
        XCTAssertEqual(70, temporaryBalance)
    }
    
    func testOverheadPaidTomorrowShare() throws {
        let overhead = Overhead(
            name: "Test1",
            amount: 280,
            dayOfPay: 28,
            lastDay: false,
            months: 2,
            startDate: startDate,
            share: true,
            imPaying: false,
            receiveDay: 27
        )
        let temporaryBalance = overhead.getTemporaryBalanceOnAccount(monthStartsOn: 25, nowDate: nowDate)
        XCTAssertEqual(140, temporaryBalance)
    }

    func testOverheadPaidTodayShare() throws {
        let overhead = Overhead(
            name: "Test1",
            amount: 280,
            dayOfPay: 27,
            lastDay: false,
            months: 2,
            startDate: startDate,
            share: true,
            imPaying: false,
            receiveDay: 27
        )
        let temporaryBalance = overhead.getTemporaryBalanceOnAccount(monthStartsOn: 25, nowDate: nowDate)
        XCTAssertEqual(0, temporaryBalance)
    }
    
    func testOverheadPaidYesterdayShare() throws {
        let overhead = Overhead(
            name: "Test1",
            amount: 280,
            dayOfPay: 26,
            lastDay: false,
            months: 2,
            startDate: startDate,
            share: true,
            imPaying: false,
            receiveDay: 27
        )
        let temporaryBalance = overhead.getTemporaryBalanceOnAccount(monthStartsOn: 25, nowDate: nowDate)
        XCTAssertEqual(0, temporaryBalance)
    }
    
    func testOverheadPaidLastMonthShare() throws {
        dateComponents.year = 2024
        dateComponents.month = 3
        dateComponents.day = 2
        nowDate = Calendar.current.date(from: dateComponents) ?? Date.now
        print(nowDate)
        
        let overhead = Overhead(
            name: "Test1",
            amount: 280,
            dayOfPay: 27,
            lastDay: false,
            months: 2,
            startDate: startDate,
            share: true,
            imPaying: false,
            receiveDay: 27
        )
        let temporaryBalance = overhead.getTemporaryBalanceOnAccount(monthStartsOn: 25, nowDate: nowDate)
        XCTAssertEqual(0, temporaryBalance)
    }
    
//    func testPerformanceExample() throws {
        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
