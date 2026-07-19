//
//  MonthlySummary.swift
//  Budget
//
//  A per-month snapshot of the planned budget figures (income, fixed costs,
//  scheduled saving) plus the realised actuals. Saved at each budget-period
//  rollover so the History view can show a truthful Netto over time — the
//  planned figures only ever exist in the *current* budget config otherwise.
//

import Foundation

struct MonthlySummary: Codable {
    // Planned figures (from the budget config at save time)
    var income: Double
    var fixedCosts: Double
    var scheduledSavings: Double

    // Realised figures for the month
    var actualIncome: Double
    var actualExpenses: Double
    var actualSavings: Double

    var saveDate: Date
    var userId: String

    /// How much was saved on top of the plan:
    /// income − fixed costs − scheduled saving − actual expenses.
    var net: Double {
        income - fixedCosts - scheduledSavings - actualExpenses
    }
}
