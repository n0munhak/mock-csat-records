//
//  PlotType.swift
//  Mock CSAT Records
//
//  Created by Seongwon Min on 7/5/26.
//

import Foundation
import Charts
import SwiftUI

struct PlotMark<X: Plottable & Hashable, Y: Plottable & Hashable>: Hashable {
    var xValue: X
    var yValue: Y
    var series: String
}

struct ConditionalPlotContainer<Content: View>: View {
    var numberOfData: Int
    @ViewBuilder var children: Content
    
    @ViewBuilder
    var body: some View {
            children
                // .frame(maxWidth: .infinity)
                .frame(height: 200)
                .padding(.vertical)
    }
}
