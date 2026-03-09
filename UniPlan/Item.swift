//
//  Item.swift
//  UniPlan
//
//  Created by Лілія Гурко on 09/03/2026.
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
