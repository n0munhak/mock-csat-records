//
//   Tamgu2StatisticsView.swift
//   Mock CSAT Records
//
//   Created by Seongwon Min on 7/5/26.
//

import SwiftUI
import SwiftData
import Charts

struct Tamgu2StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("tamgu2") private var tamgu2Selection: TamguSubjects = .societyCulture
    @Query(sort: \Tamgu2.date, order: .forward) private var _tamgu2: [Tamgu2]
    private var tamgu2: [Tamgu2] {
        _tamgu2.filter { $0.isDeleted == false }
    }
    var isRecent10 = false
    
    private var filteredTamgu2: [Tamgu2] {
        if isRecent10 {
            return Array(tamgu2.suffix(10))
        }
        return tamgu2
    }
    
    private var avgScore: Double {
        guard !filteredTamgu2.isEmpty else { return 0.0 }
        let total = filteredTamgu2.reduce(0) { $0 + $1.score }
        return Double(total) / Double(filteredTamgu2.count)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                GroupBox(label: Label("평균 점수", systemImage: "plus.forwardslash.minus")) {
                    VStack {
                        ZStack {
                            ScoreCircleView(score: avgScore, maxScore: 50.0, color: "E1F4FC")
                        }
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(tamgu2Selection.rawValue)")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                HStack(alignment: .bottom, spacing: 0) {
                                    Text(String(format: "%.1f", avgScore))
                                        .font(.title)
                                        .fontDesign(.rounded)
                                    Text(" / 50.0")
                                        .font(.subheadline)
                                        .foregroundStyle(.gray)
                                        .fontDesign(.rounded)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.primary)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding()
                
                if !filteredTamgu2.isEmpty {
                    GroupBox(label: Label("점수 변화", systemImage: "chart.line.uptrend.xyaxis")) {
                        ConditionalPlotContainer(numberOfData: filteredTamgu2.count) {
                            Chart(filteredTamgu2) {
                                LineMark(
                                    x: .value("날짜", $0.date),
                                    y: .value("점수", $0.score),
                                    series: .value("세부 과목", "\(tamgu2Selection.rawValue)")
                                )
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding()
                    GroupBox(label: Label("점수-시간 산점도", systemImage: "chart.dots.scatter")) {
                            Chart(filteredTamgu2, id: \.self) {
                                PointMark(
                                    x: .value("시간", $0.time),
                                    y: .value("점수", $0.score)
                                )
                                
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .frame(height: 200)
                            .padding(.vertical)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding()
                } else {
                    Text("기록 없음")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 40)
                }
            }
        }
        .navigationTitle("\(isRecent10 ? "최근 10회" : "전체") \(tamgu2Selection.rawValue) 실모 통계")
        .navigationBarTitleDisplayMode(.inline)
    }
}
