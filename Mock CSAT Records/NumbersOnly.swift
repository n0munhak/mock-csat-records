//
//  NumbersOnly.swift
//  Mock CSAT Records
//
//  Created by Seongwon Min on 7/3/26.
//

import Foundation
import Observation

@Observable
class NumbersOnly {
    var value = "" {
        didSet {
            let filtered = value.filter { $0.isNumber }
            
            if value != filtered {
                value = filtered
            }
        }
    }
}
