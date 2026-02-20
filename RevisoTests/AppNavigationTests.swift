//
//  AppNavigationTests.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 20/2/2026.
//

import Testing
@testable import Reviso

struct AppNavigationTests {

    @Test func defaultTab_isWorksheets() {
        let nav = AppNavigation()
        #expect(nav.selectedTab == .worksheets)
    }

    @Test func tabCases_areThree() {
        let cases = AppTab.allCases
        #expect(cases.count == 3)
        #expect(cases.contains(.worksheets))
        #expect(cases.contains(.scan))
        #expect(cases.contains(.settings))
    }
}
