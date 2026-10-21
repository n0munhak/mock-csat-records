//
//  MathHalfExamListView.swift
//  Mock CSAT Records
//
//  Created by Seongwon Min on 7/4/26.
//

import SwiftUI
import SwiftData

struct MathHalfExamListView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("math") private var mathSelection: MathSubjects = .probStat
    @AppStorage("lastUpdated") private var lastUpdated: Date = Date(timeIntervalSince1970: 0.0)
    @Query(sort: \MathHalf.date, order: .forward) private var _mathHalf: [MathHalf]
    private var math: [MathHalf] {
        _mathHalf.filter { $0.isDeleted == false }
    }
    
    var body: some View {
        NavigationStack {
            if math.isEmpty {
                Text("기록 없음")
                    .font(.title)
            } else {
                List {
                    ForEach(math.reversed()) { exam in
                        NavigationLink {
                            MathHalfExamView(uuid: exam.id)
                        } label: {
                            VStack(alignment: .leading) {
                                Label("\(getKSTDateString(from: exam.date))", systemImage: "divide")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .labelStyle(.titleAndIcon)
                                HStack {
                                    VStack {
                                        Text(exam.name)
                                            .bold()
                                            .font(.largeTitle)
                                        Text("공통: \(exam.common_score) / 32")
                                        Text("\(mathSelection.rawValue ?? "선택과목"): \(exam.selection_score) / 8")
                                    }
                                    Spacer()
                                    ZStack {
                                        ScoreCircleView(score: Double(exam.common_score + exam.selection_score), maxScore: 40.0, color: "ED028C")
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
        .navigationTitle("수학(하프) 실모 목록")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func removeItem(at indexSet: IndexSet) {
        for index in indexSet {
            if math[math.count - index - 1].syncStatus == .synced {
                math[math.count - index - 1].syncStatus = .local
            }
            let date = Date.now
            lastUpdated = date
            math[math.count - index - 1].lastUpdated = date
            math[math.count - index - 1].isDeleted = true
        }
        Task {
            await SyncManager.shared.performSync(modelContext: modelContext)
        }
    }
}
