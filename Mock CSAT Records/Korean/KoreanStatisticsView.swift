//
//   KoreanStatisticsView.swift
//   Mock CSAT Records
//
//   Created by Seongwon Min on 7/5/26.
//

import SwiftUI
import SwiftData
import Charts

struct KoreanStatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("kor") private var koreanSelection: KoreanSubjects = .easy
    @Query(sort: \Korean.date, order: .forward) private var _korean: [Korean]
    private var korean: [Korean] {
        _korean.filter { $0.isDeleted == false }
    }
    var isRecent10 = false
    
    private var filteredKorean: [Korean] {
        if isRecent10 {
            return Array(korean.suffix(10))
        }
        return korean
    }
    
    private var avgTotalScore: Double {
        guard !filteredKorean.isEmpty else { return 0.0 }
        let total = filteredKorean.reduce(0) { $0 + $1.reading_score + $1.literature_score + $1.selection_score }
        return Double(total) / Double(filteredKorean.count)
    }
    
    private var avgReadingScore: Double {
        guard !filteredKorean.isEmpty else { return 0.0 }
        let total = filteredKorean.reduce(0) { $0 + $1.reading_score }
        return Double(total) / Double(filteredKorean.count)
    }
    
    private var avgLiteratureScore: Double {
        guard !filteredKorean.isEmpty else { return 0.0 }
        let total = filteredKorean.reduce(0) { $0 + $1.literature_score }
        return Double(total) / Double(filteredKorean.count)
    }
    
    private var avgSelectionScore: Double {
        guard !filteredKorean.isEmpty else { return 0.0 }
        let total = filteredKorean.reduce(0) { $0 + $1.selection_score }
        return Double(total) / Double(filteredKorean.count)
    }
    
    private var chartData: [PlotMark<Date, Int>] {
        filteredKorean.flatMap { exam in
            [
                PlotMark(xValue: exam.date, yValue: exam.reading_score, series: "독서"),
                PlotMark(xValue: exam.date, yValue: exam.literature_score, series: "문학"),
                PlotMark(xValue: exam.date, yValue: exam.selection_score, series: koreanSelection.rawValue)
            ]
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                GroupBox(label: Label("평균 점수", systemImage: "plus.forwardslash.minus")) {
                    VStack {
                        ZStack {
                            ScoreCircleView(score: avgTotalScore, maxScore: 100.0, color: "15B68D")
                        }
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("독서")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                HStack(alignment: .bottom, spacing: 0) {
                                    Text(String(format: "%.1f", avgReadingScore))
                                        .font(.title)
                                        .fontDesign(.rounded)
                                    Text(" / 38.0")
                                        .font(.subheadline)
                                        .foregroundStyle(.gray)
                                        .fontDesign(.rounded)
                                }
                            }
                            .padding(.trailing, 8.0)
                            
                            VStack(alignment: .leading) {
                                Text("문학")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                HStack(alignment: .bottom, spacing: 0) {
                                    Text(String(format: "%.1f", avgLiteratureScore))
                                        .font(.title)
                                        .fontDesign(.rounded)
                                    Text(" / 38.0")
                                        .font(.subheadline)
                                        .foregroundStyle(.gray)
                                        .fontDesign(.rounded)
                                }
                            }
                            .padding(.trailing, 8.0)
                            
                            VStack(alignment: .leading) {
                                Text("\(koreanSelection.rawValue)")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                HStack(alignment: .bottom, spacing: 0) {
                                    Text(String(format: "%.1f", avgSelectionScore))
                                        .font(.title)
                                        .fontDesign(.rounded)
                                    Text(" / 24.0")
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
                
                if !filteredKorean.isEmpty {
                    GroupBox(label: Label("총점 변화", systemImage: "chart.line.uptrend.xyaxis")) {
                        ConditionalPlotContainer(numberOfData: filteredKorean.count) {
                            Chart(filteredKorean) {
                                LineMark(
                                    x: .value("날짜", $0.date),
                                    y: .value("점수", $0.reading_score + $0.literature_score + $0.selection_score),
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
                        ConditionalPlotContainer(numberOfData: filteredKorean.count) {
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
                            Chart(filteredKorean, id: \.self) {
                                PointMark(
                                    x: .value("시간", $0.time),
                                    y: .value("점수", $0.reading_score + $0.literature_score + $0.selection_score)
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
        .navigationTitle("\(isRecent10 ? "최근 10회" : "전체") 국어 실모 통계")
        .navigationBarTitleDisplayMode(.inline)
    }
}
