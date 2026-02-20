//
//  AppNavigation.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 20/2/2026.
//

import Foundation

enum AppTab: Int, CaseIterable {
    case worksheets
    case scan
}

@Observable
final class AppNavigation {
    var selectedTab: AppTab = .worksheets
}
