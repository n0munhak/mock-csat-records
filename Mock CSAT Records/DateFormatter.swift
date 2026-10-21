//
//  DateFormatter.swift
//  Mock CSAT Records
//
//  Created by Seongwon Min on 7/4/26.
//

import Foundation

func getKSTDateString(from date: Date = Date()) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
    formatter.locale = Locale(identifier: "ko_KR")
    return formatter.string(from: date)
}
