//
//  Tamgu2xamListView.swift
//  Mock CSAT Records
//
//  Created by Seongwon Min on 7/4/26.
//

import SwiftUI
import SwiftData

struct Tamgu2ExamListView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("tamgu2") private var tamgu2Selection: TamguSubjects = .societyCulture
    @AppStorage("lastUpdated") private var lastUpdated: Date = Date(timeIntervalSince1970: 0.0)
    @Query(sort: \Tamgu2.date, order: .forward) private var _tamgu2: [Tamgu2]
    private var tamgu2: [Tamgu2] {
        _tamgu2.filter { $0.isDeleted == false }
    }
    
    var body: some View {
        NavigationStack {
            if tamgu2.isEmpty {
                Text("기록 없음")
                    .font(.title)
            } else {
                List {
                    ForEach(tamgu2.reversed()) { exam in
                        NavigationLink {
                            Tamgu2ExamView(uuid: exam.id)
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
                                        ScoreCircleView(score: Double(exam.score), maxScore: 50.0, color: "E1F4FC")
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
        .navigationTitle("\(tamgu2Selection.rawValue ?? "탐구2") 실모 목록")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func removeItem(at indexSet: IndexSet) {
        for index in indexSet {
            if tamgu2[tamgu2.count - index - 1].syncStatus == .synced {
                tamgu2[tamgu2.count - index - 1].syncStatus = .local
            }
            let date = Date.now
            lastUpdated = date
            tamgu2[tamgu2.count - index - 1].lastUpdated = date
            tamgu2[tamgu2.count - index - 1].isDeleted = true
        }
        Task {
            await SyncManager.shared.performSync(modelContext: modelContext)
        }
    }
}
