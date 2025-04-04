//
//  TabRouter.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2025-04-05.
//


class TabRouter: ObservableObject {
    @Published var selectedTab: Tab = .home
    
    enum Tab {
        case home
        case transactions
        case standings
        case history
        case settings
    }
}
