//
//  KoreanExamView.swift
//  Mock CSAT Records
//
//  Created by Seongwon Min on 7/4/26.
//

import SwiftUI
import SwiftData

struct KoreanExamView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("kor") private var koreanSelection: KoreanSubjects = .easy
    @Query(sort: \Korean.date, order: .forward) private var _korean: [Korean]
    private var korean: [Korean] {
        _korean.filter { $0.isDeleted == false }
    }
    var uuid: UUID
    
    var body: some View {
        if let exam = korean.first(where: { $0.id == self.uuid }) {
            NavigationStack {
                ScrollView {
                    LargeScoreCircleView(score: Double(exam.reading_score + exam.literature_score + exam.selection_score), color: "15B68D")
                        .padding(.vertical)
                    GroupBox(label: Label("소요 시간", systemImage: "clock.fill")) {
                        Text("\(exam.time) / 80분")
                            .font(.largeTitle)
                            .fontDesign(.rounded)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color(.secondarySystemGroupedBackground))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal)
                    GroupBox(label: Label("독서", systemImage: "book.and.wrench.fill")) {
                        HStack {
                            Text("\(exam.reading_score) / 38")
                                .font(.largeTitle)
                                .fontDesign(.rounded)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            VStack(alignment: .trailing) {
                                Text("오답 문항 번호")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                    .bold()
                                Text(exam.reading_wrong)
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
                    GroupBox(label: Label("문학", systemImage: "book.fill")) {
                        HStack {
                            Text("\(exam.literature_score) / 38")
                                .font(.largeTitle)
                                .fontDesign(.rounded)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            VStack(alignment: .trailing) {
                                Text("오답 문항 번호")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                    .bold()
                                Text(exam.literature_wrong)
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
                    GroupBox(label: Label("\(koreanSelection.rawValue)", systemImage: "characters.uppercase")) {
                        HStack {
                            Text("\(exam.selection_score) / 24")
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
