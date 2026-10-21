//
//  Tamgu2View.swift
//  Mock CSAT Records
//
//  Created by Seongwon Min on 7/4/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct Tamgu2View: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("tamgu2") private var tamgu2Selection: TamguSubjects = .societyCulture
    @AppStorage("lastUpdated") private var lastUpdated: Date = Date(timeIntervalSince1970: 0.0)
    @Query(sort: \Tamgu2.date, order: .forward) private var _tamgu2: [Tamgu2]
    private var tamgu2: [Tamgu2] {
        _tamgu2.filter { $0.isDeleted == false }
    }
    @State private var showAddModal = false
    @State private var add_name = ""
    @State private var add_time = NumbersOnly()
    @State private var add_score1 = NumbersOnly()
    @State private var add_wrong1 = ""
    @State private var add_reason = ""
    @State private var isExporting = false
    
    private var formattedAvgScore: Double {
        guard !tamgu2.isEmpty else { return 0.0 }
        
        let totalScore = tamgu2.reduce(0) { $0 + $1.score }
        let average = Double(totalScore) / Double(tamgu2.count)
        
        return average
    }
    
    private func exportCSV() -> URL {
        let csvWithoutBom = tamgu2.enumerated().map { ($0, $1) }.reduce("순번,날짜,실모 이름,소요시간(분),점수,오답,틀린 이유") { $0 + "\n\($1.0 + 1),\(getKSTDateString(from: $1.1.date)),\"\($1.1.name)\",\($1.1.time),\($1.1.score),\"\($1.1.wrong)\",\"\($1.1.reason)\"" }
        let base64 = csvWithoutBom.data(using: .utf8)!.base64EncodedString()
        let csvWithBom = Data(base64Encoded: "77u/" + base64)!
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("탐구(\(tamgu2Selection.rawValue ?? "제2선택")).csv")
        try? csvWithBom.write(to: tempURL)
        return tempURL
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if (tamgu2.isEmpty) {
                    Text("기록 없음")
                        .font(.title)
                } else {
                    ScrollView {
                        NavigationLink {
                            Tamgu2ExamView(uuid: tamgu2.last!.id)
                        } label: {
                            GroupBox(label: Label("최근 실모", systemImage: "clock.badge.fill")) {
                                HStack {
                                    VStack {
                                        Text(tamgu2.last!.name)
                                            .bold()
                                            .font(.largeTitle)
                                        Text("점수: \(tamgu2.last!.score) / 50")
                                    }
                                    Spacer()
                                    ZStack {
                                        ScoreCircleView(score: Double(tamgu2.last!.score), maxScore: 50.0, color: "E1F4FC")
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
                        if (tamgu2.count >= 10) {
                            NavigationLink {
                                Tamgu2StatisticsView(isRecent10: true)
                            } label: {
                                GroupBox(label: Label("최근 10개 실모", systemImage: "10.circle.fill")) {
                                    HStack {
                                        VStack {
                                            Text("최근 10개 실모")
                                                .font(.largeTitle)
                                                .bold()
                                            Text("점수: \(String(format: "%.1f", Double(tamgu2.suffix(10).reduce(0, { $0 + $1.score })) / 10.0)) / 50.0")
                                        }
                                        Spacer()
                                        ZStack {
                                            ScoreCircleView(score: Double(tamgu2.suffix(10).reduce(0, { $0 + $1.score }) / 10), maxScore: 50.0, color: "E1F4FC")
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
                                        ScoreCircleView(score: -1, color: "E1F4FC")
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 100.0, alignment: .center)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal)
                        }
                        NavigationLink {
                            Tamgu2StatisticsView(isRecent10: false)
                        } label: {
                            GroupBox(label: Label("전체 실모", systemImage: "square.3.layers.3d")) {
                                HStack {
                                    VStack {
                                        Text("전체 실모")
                                            .font(.largeTitle)
                                            .bold()
                                        Text("점수: \(String(format: "%.1f", formattedAvgScore)) / 50.0")
                                    }
                                    Spacer()
                                    ZStack {
                                        ScoreCircleView(score: formattedAvgScore, maxScore: 50.0, color: "E1F4FC")
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
                            Tamgu2ExamListView()
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
            .navigationTitle("탐구(\(tamgu2Selection.rawValue ?? "제2선택"))")
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
            add_wrong1 = ""
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
                    LabeledContent("점수") {
                        TextField("입력", text: $add_score1.value)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                Section(header: Text("오답")) {
                    LabeledContent("오답 문항 번호") {
                        TextField("입력", text: $add_wrong1)
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
            .disabled(add_name == "" || add_time.value == "" || add_score1.value == "")
        }
    }
    
    private func saveSettings() {
        let record = Tamgu2(syncStatus: .local, name: add_name, time: Int(add_time.value) ?? 0, score: Int(add_score1.value) ?? 0, wrong: add_wrong1, reason: add_reason)
        modelContext.insert(record)
        lastUpdated = record.lastUpdated
        Task {
            await SyncManager.shared.performSync(modelContext: modelContext)
        }
        showAddModal = false;
    }
}
