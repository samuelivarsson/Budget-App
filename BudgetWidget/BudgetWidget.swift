//
//  BudgetWidget.swift
//  BudgetWidget
//
//  Created by Samuel Ivarsson on 2023-03-28.
//

import Firebase
import Intents
import SwiftUI
import WidgetKit

struct Provider: IntentTimelineProvider {
    private var quickBalanceViewModel = QuickBalanceViewModel()

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date.now, balance: "1234,56", currency: "SEK", error: "", configuration: SelectAccountIntent())
    }

    func getSnapshot(for configuration: SelectAccountIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date.now, balance: "1234,56", currency: "SEK", error: "", configuration: SelectAccountIntent())
        completion(entry)
    }

    func getTimeline(for configuration: SelectAccountIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        guard let budgetAccountId = configuration.account?.budgetAccountId else {
            completion(Timeline(entries: entries, policy: .after(Date(timeInterval: 15, since: Date.now))))
            return
        }

        let prevBalance = self.quickBalanceViewModel.getRawQuickBalance(budgetAccountId: budgetAccountId)
        let prevCurrency = self.quickBalanceViewModel.getCurrency(budgetAccountId: budgetAccountId)

        self.fetchQuickBalance(configuration: configuration, budgetAccountId: budgetAccountId) { error in
            if let error = error {
                print(error.localizedDescription)
                let entry = SimpleEntry(date: Date.now, balance: prevBalance, currency: prevCurrency, error: error.localizedDescription, configuration: configuration)
                let entry2 = SimpleEntry(date: Date(timeIntervalSinceNow: 5), balance: prevBalance, currency: prevCurrency, error: "", configuration: configuration)
                completion(Timeline(entries: [entry, entry2], policy: .after(Date(timeInterval: 15, since: Date.now))))
                return
            }

            // Success
            let newBalance = self.quickBalanceViewModel.getRawQuickBalance(budgetAccountId: budgetAccountId)
            let newCurrency = self.quickBalanceViewModel.getCurrency(budgetAccountId: budgetAccountId)
            let expirationMessage = self.quickBalanceViewModel.getExpirationMessage(budgetAccountId: budgetAccountId)

            let entry = SimpleEntry(date: Date.now, balance: newBalance, currency: newCurrency, error: expirationMessage, configuration: configuration)
            entries.append(entry)

            let timeline = Timeline(entries: entries, policy: .never)
            completion(timeline)
        }
    }

    private func fetchQuickBalance(configuration: SelectAccountIntent, budgetAccountId: String, completion: @escaping (Error?) -> ()) {
        guard let _ = Auth.auth().currentUser else {
            completion(UserError.notLoggedIn)
            return
        }

        guard let name = configuration.account?.name else {
            let info = "Found nil when extracting name in fetchQuickBalance in Provider (Widget)"
            completion(ApplicationError.unexpectedNil(info))
            return
        }

        guard let subscriptionId = configuration.account?.subscriptionId else {
            let info = "Found nil when extracting subscriptionId in fetchQuickBalance in Provider (Widget)"
            completion(ApplicationError.unexpectedNil(info))
            return
        }

        let quickBalanceAccount = QuickBalanceAccount(name: name, subscriptionId: subscriptionId, budgetAccountId: budgetAccountId)
        self.quickBalanceViewModel.fetchQuickBalanceFromApi(quickBalanceAccount: quickBalanceAccount, completion: completion)
    }
}

struct SimpleEntry: TimelineEntry {
    var date: Date
    let balance: String
    let currency: String
    let error: String
    let configuration: SelectAccountIntent
}

struct SingleQuickBalanceWidgetEntryView: View {
    @Environment(\.colorScheme) var colorScheme

    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            let balanceText = self.entry.balance + " " + self.entry.currency
            Text("amountAvailable".localizeString())
                .font(.system(size: 13))

            Text(balanceText)
                .font(.system(size: 22))
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.3)

            if self.entry.error.isEmpty {
                HStack(spacing: 0) {
                    Text("\("latestUpdate".localizeString()): ")
                        .font(.system(size: 9))
                    Text(self.entry.date, style: .time)
                        .font(.system(size: 9))
                }
            } else {
                Text(self.entry.error)
                    .font(.system(size: 8))
                    .bold()
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .widgetURL(URL(string: "budgetapp://?sourceApplication=widget&kind=singleQuickBalance"))
        .widgetBackground(self.colorScheme == .dark ? Color(red: 44/255, green: 44/255, blue: 44/255) : Color.white)
    }
}

struct SingleQuickBalanceWidget: Widget {
    let kind: String = "singleQuickBalance"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: self.kind, intent: SelectAccountIntent.self, provider: Provider()) { entry in
            SingleQuickBalanceWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("quickBalance".localizeString())
        .description("seeYourQuickBalance".localizeString())
        .contentMarginsDisabled()
    }
}

struct SingleQuickBalanceWidget_Previews: PreviewProvider {
    static var previews: some View {
        SingleQuickBalanceWidgetEntryView(entry: SimpleEntry(date: Date.now, balance: "1234,56", currency: "SEK", error: "", configuration: SelectAccountIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

extension View {
    func widgetBackground(_ backgroundView: some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView)
        }
    }
}
