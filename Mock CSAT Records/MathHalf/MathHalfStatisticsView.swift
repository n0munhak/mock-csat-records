//
//   MathHalfStatisticsView.swift
//   Mock CSAT Records
//
//   Created by Seongwon Min on 7/5/26.
//

import SwiftUI
import SwiftData
import Charts

struct MathHalfStatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("math") private var mathSelection: MathSubjects = .probStat
    @Query(sort: \MathHalf.date, order: .forward) private var _mathHalf: [MathHalf]
    private var math: [MathHalf] {
        _mathHalf.filter { $0.isDeleted == false }
    }
    var isRecent10 = false
    
    private var filteredMath: [MathHalf] {
        if isRecent10 {
            return Array(math.suffix(10))
        }
        return math
    }
    
    private var avgTotalScore: Double {
        guard !filteredMath.isEmpty else { return 0.0 }
        let total = filteredMath.reduce(0) { $0 + $1.common_score + $1.selection_score }
        return Double(total) / Double(filteredMath.count)
    }
    
    private var avgCommonScore: Double {
        guard !filteredMath.isEmpty else { return 0.0 }
        let total = filteredMath.reduce(0) { $0 + $1.common_score }
        return Double(total) / Double(filteredMath.count)
    }
    
    private var avgSelectionScore: Double {
        guard !filteredMath.isEmpty else { return 0.0 }
        let total = filteredMath.reduce(0) { $0 + $1.selection_score }
        return Double(total) / Double(filteredMath.count)
    }
    
    private var chartData: [PlotMark<Date, Int>] {
        filteredMath.flatMap { exam in
            [
                PlotMark(xValue: exam.date, yValue: exam.common_score, series: "공통(수학 I, 수학 II)"),
                PlotMark(xValue: exam.date, yValue: exam.selection_score, series: mathSelection.rawValue)
            ]
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                GroupBox(label: Label("평균 점수", systemImage: "plus.forwardslash.minus")) {
                    VStack {
                        ZStack {
                            ScoreCircleView(score: avgTotalScore, maxScore: 40.0, color: "ED028C")
                        }
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("공통(수학 I, 수학 II)")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                HStack(alignment: .bottom, spacing: 0) {
                                    Text(String(format: "%.1f", avgCommonScore))
                                        .font(.title)
                                        .fontDesign(.rounded)
                                    Text(" / 32.0")
                                        .font(.subheadline)
                                        .foregroundStyle(.gray)
                                        .fontDesign(.rounded)
                                }
                            }
                            .padding(.trailing, 8.0)
                            
                            VStack(alignment: .leading) {
                                Text("\(mathSelection.rawValue)")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                HStack(alignment: .bottom, spacing: 0) {
                                    Text(String(format: "%.1f", avgSelectionScore))
                                        .font(.title)
                                        .fontDesign(.rounded)
                                    Text(" / 8.0")
                                        .font(.subheadline)
                                        .foregroundStyle(.gray)
                                        .fontDesign(.rounded)
                                }
                            }
                            .padding(.trailing, 4.0)
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
                
                if !filteredMath.isEmpty {
                    GroupBox(label: Label("총점 변화", systemImage: "chart.line.uptrend.xyaxis")) {
                        ConditionalPlotContainer(numberOfData: filteredMath.count) {
                            Chart(filteredMath) {
                                LineMark(
                                    x: .value("날짜", $0.date),
                                    y: .value("점수", $0.common_score + $0.selection_score),
                                    series: .value("세부 과목", "총점")
                                )
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding()
                    
                    GroupBox(label: Label("세부 과목별 점수 변화", systemImage: "chart.line.uptrend.xyaxis")) {
                        ConditionalPlotContainer(numberOfData: filteredMath.count) {
                            Chart(chartData, id: \.self) {
                                LineMark(
                                    x: .value("날짜", $0.xValue),
                                    y: .value("점수", $0.yValue)
                                )
                                .foregroundStyle(by: .value("세부 과목", $0.series))
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding()
                    GroupBox(label: Label("점수-시간 산점도", systemImage: "chart.dots.scatter")) {
                            Chart(filteredMath, id: \.self) {
                                PointMark(
                                    x: .value("시간", $0.time),
                                    y: .value("점수", $0.common_score + $0.selection_score)
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
        .navigationTitle("\(isRecent10 ? "최근 10회" : "전체") 수학(하프) 실모 통계")
        .navigationBarTitleDisplayMode(.inline)
    }
}
