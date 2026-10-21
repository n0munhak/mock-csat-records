//
//  Tamgu2ExamView.swift
//  Mock CSAT Records
//
//  Created by Seongwon Min on 7/4/26.
//

import SwiftUI
import SwiftData

struct Tamgu2ExamView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("tamgu2") private var tamgu2Selection: TamguSubjects = .societyCulture
    @Query(sort: \Tamgu2.date, order: .forward) private var _tamgu2: [Tamgu2]
    private var tamgu2: [Tamgu2] {
        _tamgu2.filter { $0.isDeleted == false }
    }
    var uuid: UUID
    
    var body: some View {
        if let exam = tamgu2.first(where: { $0.id == self.uuid }) {
            NavigationStack {
                ScrollView {
                    LargeScoreCircleView(score: Double(exam.score), maxScore: 50.0, color: "E1F4FC")
                        .padding(.vertical)
                    GroupBox(label: Label("소요 시간", systemImage: "clock.fill")) {
                        Text("\(exam.time) / 30분")
                            .font(.largeTitle)
                            .fontDesign(.rounded)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color(.secondarySystemGroupedBackground))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal)
                    GroupBox(label: Label("점수", systemImage: "flask")) {
                        HStack {
                            Text("\(exam.score) / 50")
                                .font(.largeTitle)
                                .fontDesign(.rounded)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            VStack(alignment: .trailing) {
                                Text("오답 문항 번호")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                    .bold()
                                Text(exam.wrong)
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
