//
//  MathHalfExamView.swift
//  Mock CSAT Records
//
//  Created by Seongwon Min on 7/4/26.
//

import SwiftUI
import SwiftData

struct MathHalfExamView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("math") private var mathSelection: MathSubjects = .probStat
    @Query(sort: \MathHalf.date, order: .forward) private var _mathHalf: [MathHalf]
    private var math: [MathHalf] {
        _mathHalf.filter { $0.isDeleted == false }
    }
    var uuid: UUID
    
    var body: some View {
        if let exam = math.first(where: { $0.id == self.uuid }) {
            NavigationStack {
                ScrollView {
                    LargeScoreCircleView(score: Double(exam.common_score + exam.selection_score), maxScore: 40.0, color: "ED028C")
                        .padding(.vertical)
                    GroupBox(label: Label("소요 시간", systemImage: "clock.fill")) {
                        Text("\(exam.time)분")
                            .font(.largeTitle)
                            .fontDesign(.rounded)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color(.secondarySystemGroupedBackground))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal)
                    GroupBox(label: Label("공통(수학 I, 수학 II)", systemImage: "function")) {
                        HStack {
                            Text("\(exam.common_score) / 32")
                                .font(.largeTitle)
                                .fontDesign(.rounded)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            VStack(alignment: .trailing) {
                                Text("오답 문항 번호")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                    .bold()
                                Text(exam.common_wrong)
                                    .font(.title2)
                                    .fontDesign(.rounded)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color(.secondarySystemGroupedBackground))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal)
                    GroupBox(label: Label("\(mathSelection.rawValue)", systemImage: "graph.2d")) {
                        HStack {
                            Text("\(exam.selection_score) / 8")
                                .font(.largeTitle)
                                .fontDesign(.rounded)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            VStack(alignment: .trailing) {
                                Text("오답 문항 번호")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                    .bold()
                                Text(exam.selection_wrong)
                                    .font(.title2)
                                    .fontDesign(.rounded)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color(.secondarySystemGroupedBackground))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal)
                    GroupBox(label: Label("틀린 이유", systemImage: "pencil.slash")) {
                        Text("\(exam.reason)")
                            .fontDesign(.monospaced)
                            .padding()
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color(.secondarySystemGroupedBackground))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal)
                }
            }
            .navigationTitle("\(exam.name)")
            .navigationBarTitleDisplayMode(.inline)
        } else {
            Text("Error...")
        }
    }
}
