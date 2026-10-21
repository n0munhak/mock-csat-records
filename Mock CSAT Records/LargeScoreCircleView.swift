//
//  LargeScoreCircleView.swift
//  Mock CSAT Records
//
//  Created by Seongwon Min on 7/4/26.
//

import SwiftUI

struct LargeScoreCircleView: View {
    var score: Double
    var maxScore = 100.0
    var color: String
    
    private var progress: CGFloat {
        return CGFloat(min(max(score, 0.0) / maxScore, 1.0))
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 24)
            
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(
                    Color(hex: color),
                    style: StrokeStyle(lineWidth: 24, lineCap: .round)
                )
                .rotationEffect(Angle(degrees: -90))
                .animation(.easeOut(duration: 0.8), value: score)
            
            VStack(spacing: 4) {
                Text("\(score == -1 ? "--" : "\(Int(score))/\(Int(maxScore))")")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
            }
        }
        .frame(width: 240, height: 240)
        .padding()
    }
}
