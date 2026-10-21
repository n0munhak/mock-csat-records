//
//  MathHalfView.swift
//  Mock CSAT Records
//
//  Created by Seongwon Min on 7/4/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct MathHalfView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("math") private var mathSelection: MathSubjects = .probStat
    @AppStorage("lastUpdated") private var lastUpdated: Date = Date(timeIntervalSince1970: 0.0)
    @Query(sort: \MathHalf.date, order: .forward) private var _mathHalf: [MathHalf]
    private var math: [MathHalf] {
        _mathHalf.filter { $0.isDeleted == false }
    }
    @State private var showAddModal = false
    @State private var add_name = ""
    @State private var add_time = NumbersOnly()
    @State private var add_score1 = NumbersOnly()
    @State private var add_score2 = NumbersOnly()
    @State private var add_wrong1 = ""
    @State private var add_wrong2 = ""
    @State private var add_reason = ""
    @State private var isExporting = false
    
    private var formattedAvgScore1: String {
        guard !math.isEmpty else { return "0.0" }
        
        let totalScore = math.reduce(0) { $0 + $1.common_score }
        let average = Double(totalScore) / Double(math.count)
        
        let roundedValue = (average * 10.0).rounded(.down) / 10.0
        
        return String(format: "%.1f", roundedValue)
    }
    
    private var formattedAvgScore2: String {
        guard !math.isEmpty else { return "0.0" }
        
        let totalScore = math.reduce(0) { $0 + $1.selection_score }
        let average = Double(totalScore) / Double(math.count)
        
        let roundedValue = (average * 10.0).rounded(.down) / 10.0
        
        return String(format: "%.1f", roundedValue)
    }
    
    private var formattedAvgTotalScore: Double {
        guard !math.isEmpty else { return 0.0 }
        
        let totalScore = math.reduce(0) { $0 + $1.common_score + $1.selection_score }
        let average = Double(totalScore) / Double(math.count)
        
        return average
    }
    
    private func exportCSV() -> URL {
        let csvWithoutBom = math.enumerated().map { ($0, $1) }.reduce("순번,날짜,실모 이름,소요시간(분),총점,공통 점수,\(mathSelection.rawValue) 점수,공통 오답,\(mathSelection.rawValue) 오답,틀린 이유") { $0 + "\n\($1.0 + 1),\(getKSTDateString(from: $1.1.date)),\"\($1.1.name)\",\($1.1.time),\($1.1.common_score+$1.1.selection_score),\($1.1.common_score),\($1.1.selection_score),\"\($1.1.common_wrong)\",\"\($1.1.selection_wrong)\",\"\($1.1.reason)\"" }
        let base64 = csvWithoutBom.data(using: .utf8)!.base64EncodedString()
        let csvWithBom = Data(base64Encoded: "77u/" + base64)!
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("수학(하프).csv")
        try? csvWithBom.write(to: tempURL)
        return tempURL
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if (math.isEmpty) {
                    Text("기록 없음")
                        .font(.title)
                } else {
                    ScrollView {
                        NavigationLink {
                            MathHalfExamView(uuid: math.last!.id)
                        } label: {
                            GroupBox(label: Label("최근 실모", systemImage: "clock.badge.fill")) {
                                HStack {
                                    VStack {
                                        Text(math.last!.name)
                                            .bold()
                                            .font(.largeTitle)
                                        Text("공통: \(math.last!.common_score) / 32")
                                        Text("\(mathSelection.rawValue ?? "선택과목"): \(math.last!.selection_score) / 8")
                                    }
                                    Spacer()
                                    ZStack {
                                        ScoreCircleView(score: Double(math.last!.common_score + math.last!.selection_score), maxScore: 40.0, color: "ED028C")
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(.primary)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        if (math.count >= 10) {
                            NavigationLink {
                                MathHalfStatisticsView(isRecent10: true)
                            } label: {
                                GroupBox(label: Label("최근 10개 실모", systemImage: "10.circle.fill")) {
                                    HStack {
                                        VStack {
                                            Text("최근 10개 실모")
                                                .font(.largeTitle)
                                                .bold()
                                            Text("공통: \(String(format: "%.1f", Double(math.suffix(10).reduce(0, { $0 + $1.common_score })) / 10.0)) / 32.0")
                                            Text("\(mathSelection.rawValue ?? "선택과목"): \(String(format: "%.1f", Double(math.suffix(10).reduce(0, { $0 + $1.selection_score })) / 10.0)) / 8.0")
                                        }
                                        Spacer()
                                        ZStack {
                                            ScoreCircleView(score: Double(math.suffix(10).reduce(0, { $0 + $1.common_score + $1.selection_score }) / 10), maxScore: 40.0, color: "ED028C")
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemGroupedBackground))
                                .foregroundStyle(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        } else {
                            GroupBox(label: Label("최근 10개 실모", systemImage: "10.circle.fill")) {
                                HStack {
                                    Text("데이터 부족")
                                        .font(.largeTitle)
                                    Spacer()
                                    ZStack {
                                        ScoreCircleView(score: -1, color: "ED028C")
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 100.0, alignment: .center)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal)
                        }
                        NavigationLink {
                            MathHalfStatisticsView(isRecent10: false)
                        } label: {
                            GroupBox(label: Label("전체 실모", systemImage: "square.3.layers.3d")) {
                                HStack {
                                    VStack {
                                        Text("전체 실모")
                                            .font(.largeTitle)
                                            .bold()
                                        Text("공통: \(formattedAvgScore1) / 32.0")
                                        Text("\(mathSelection.rawValue ?? "선택과목"): \(formattedAvgScore2) / 8.0")
                                    }
                                    Spacer()
                                    ZStack {
                                        ScoreCircleView(score: formattedAvgTotalScore, maxScore: 40.0, color: "ED028C")
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(.primary)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        NavigationLink {
                            MathHalfExamListView()
                        } label: {
                            Label("실모 기록 더보기", systemImage: "ellipsis.circle.fill")
                                .padding()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.primary)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal)
                        ShareLink(item: exportCSV()) {
                            Label("CSV(Excel) 파일로 내보내기", systemImage: "tablecells.fill")
                                .padding()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.primary)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("수학 - 하프(\(mathSelection.rawValue ?? "선택과목 없음"))")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddModal = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddModal, onDismiss: {
            add_name = ""
            add_time.value = ""
            add_score1.value = ""
            add_score2.value = ""
            add_wrong1 = ""
            add_wrong2 = ""
            add_reason = ""
        }) {
            Form {
                Section(header: Text("기본 정보")) {
                    LabeledContent("실모 이름") {
                        TextField("입력", text: $add_name)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("소요 시간(분)") {
                        TextField("입력", text: $add_time.value)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                Section(header: Text("점수")) {
                    LabeledContent("공통(수학 I, 수학 II) 점수") {
                        TextField("입력", text: $add_score1.value)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("\(mathSelection.rawValue ?? "선택과목") 점수") {
                        TextField("입력", text: $add_score2.value)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                Section(header: Text("오답")) {
                    LabeledContent("공통 오답 문항 번호") {
                        TextField("입력", text: $add_wrong1)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("\(mathSelection.rawValue ?? "선택과목") 오답 문항 번호") {
                        TextField("입력", text: $add_wrong2)
                            .multilineTextAlignment(.trailing)
                    }
                }
                Section(header: Text("틀린 이유")) {
                    TextField("입력", text: $add_reason, axis: .vertical)
                }
            }
            .padding(.top)
            Button(action: saveSettings) {
                Text("완료")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .padding()
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .background(Color(.systemGroupedBackground))
            .disabled(add_name == "" || add_time.value == "" || add_score1.value == "" || add_score2.value == "")
        }
    }
    
    private func saveSettings() {
        let record = MathHalf(syncStatus: .local, name: add_name, time: Int(add_time.value) ?? 0, common_score: Int(add_score1.value) ?? 0, selection_score: Int(add_score2.value) ?? 0, common_wrong: add_wrong1, selection_wrong: add_wrong2, reason: add_reason)
        lastUpdated = record.lastUpdated
        modelContext.insert(record)
        Task {
            await SyncManager.shared.performSync(modelContext: modelContext)
        }
        showAddModal = false;
    }
}
