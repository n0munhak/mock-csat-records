//
//  Tamgu1ExamListView.swift
//  Mock CSAT Records
//
//  Created by Seongwon Min on 7/4/26.
//

import SwiftUI
import SwiftData

struct Tamgu1ExamListView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("tamgu1") private var tamgu1Selection: TamguSubjects = .ethics1
    @AppStorage("lastUpdated") private var lastUpdated: Date = Date(timeIntervalSince1970: 0.0)
    @Query(sort: \Tamgu1.date, order: .forward) private var _tamgu1: [Tamgu1]
    private var tamgu1: [Tamgu1] {
        _tamgu1.filter { $0.isDeleted == false }
    }
    
    var body: some View {
        NavigationStack {
            if tamgu1.isEmpty {
                Text("기록 없음")
                    .font(.title)
            } else {
                List {
                    ForEach(tamgu1.reversed()) { exam in
                        NavigationLink {
                            Tamgu1ExamView(uuid: exam.id)
                        } label: {
                            VStack(alignment: .leading) {
                                Label("\(getKSTDateString(from: exam.date))", systemImage: "flask")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .labelStyle(.titleAndIcon)
                                HStack {
                                    VStack {
                                        Text(exam.name)
                                            .bold()
                                            .font(.largeTitle)
                                        Text("점수: \(exam.score) / 50")
                                    }
                                    Spacer()
                                    ZStack {
                                        ScoreCircleView(score: Double(exam.score), maxScore: 50.0, color: "015196")
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
        .navigationTitle("\(tamgu1Selection.rawValue ?? "탐구1") 실모 목록")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func removeItem(at indexSet: IndexSet) {
        for index in indexSet {
            if tamgu1[tamgu1.count - index - 1].syncStatus == .synced {
                tamgu1[tamgu1.count - index - 1].syncStatus = .local
            }
            let date = Date.now
            lastUpdated = date
            tamgu1[tamgu1.count - index - 1].lastUpdated = date
            tamgu1[tamgu1.count - index - 1].isDeleted = true
        }
        Task {
            await SyncManager.shared.performSync(modelContext: modelContext)
        }
    }
}
