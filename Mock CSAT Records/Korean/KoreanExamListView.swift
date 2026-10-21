//
//  KoreanExamListView.swift
//  Mock CSAT Records
//
//  Created by Seongwon Min on 7/4/26.
//

import SwiftUI
import SwiftData

struct KoreanExamListView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("kor") private var koreanSelection: KoreanSubjects = .easy
    @AppStorage("lastUpdated") private var lastUpdated: Date = Date(timeIntervalSince1970: 0.0)
    @Query(sort: \Korean.date, order: .forward) private var _korean: [Korean]
    private var korean: [Korean] {
        _korean.filter { $0.isDeleted == false }
    }
    
    var body: some View {
        NavigationStack {
            if korean.isEmpty {
                Text("기록 없음")
                    .font(.title)
            } else {
                List {
                    ForEach(korean.reversed()) { exam in
                        NavigationLink {
                            KoreanExamView(uuid: exam.id)
                        } label: {
                            VStack(alignment: .leading) {
                                Label("\(getKSTDateString(from: exam.date))", systemImage: "text.page")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .labelStyle(.titleAndIcon)
                                HStack {
                                    VStack {
                                        Text(exam.name)
                                            .bold()
                                            .font(.largeTitle)
                                        Text("독서: \(exam.reading_score) / 38")
                                        Text("문학: \(exam.literature_score) / 38")
                                        Text("\(koreanSelection.rawValue ?? "선택과목"): \(exam.selection_score) / 24")
                                    }
                                    Spacer()
                                    ZStack {
                                        ScoreCircleView(score: Double(exam.reading_score + exam.literature_score + exam.selection_score), color: "15B68D")
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(.primary)
                            }
                            .padding()
                        }
                    }
                    .onDelete(perform: removeItem)
                }
            }
        }
        .navigationTitle("국어 실모 목록")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func removeItem(at indexSet: IndexSet) {
        for index in indexSet {
            if korean[korean.count - index - 1].syncStatus == .synced {
                korean[korean.count - index - 1].syncStatus = .local
            }
            let date = Date.now
            lastUpdated = date
            korean[korean.count - index - 1].lastUpdated = date
            korean[korean.count - index - 1].isDeleted = true
        }
        Task {
            await SyncManager.shared.performSync(modelContext: modelContext)
        }
    }
}
