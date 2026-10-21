//
//  SharedModelContainer.swift
//  Mock CSAT Records
//
//  Created by Seongwon Min on 8/8/26.
//


import Foundation
import SwiftData

enum SharedModelContainer {
    static let container: ModelContainer = {
        let schema = Schema([
            Korean.self,
            Math.self,
            MathHalf.self,
            Tamgu1.self,
            Tamgu2.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("\(error)")
        }
    }()
}
