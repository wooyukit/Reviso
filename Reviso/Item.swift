//
//  Item.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
