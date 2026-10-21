//
//  CircleProgressView.swift
//  Mock CSAT Records
//
//  Created by Seongwon Min on 7/4/26.
//

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 1) // Fallback to white if invalid
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ScoreCircleView: View {
    var score: Double
    var maxScore = 100.0
    var color: String
    
    private var progress: CGFloat {
        return CGFloat(min(max(score, 0.0) / maxScore, 1.0))
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 12)
            
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(
                    Color(hex: color),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(Angle(degrees: -90))
                .animation(.easeOut(duration: 0.8), value: score)
            
            VStack(spacing: 4) {
                Text("\(score == -1 ? "--" : "\(String(format: "%.1f", score))")")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
        }
        .frame(width: 80, height: 80)
        .padding()
    }
}
