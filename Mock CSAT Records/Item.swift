//
//  Item.swift
//  Mock CSAT Records
//
//  Created by Seongwon Min on 7/2/26.
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
