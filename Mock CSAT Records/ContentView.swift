//
//  ContentView.swift
//  Mock CSAT Records
//
//  Created by Seongwon Min on 7/2/26.
//

import SwiftUI
import UIKit
import SwiftData
import ZIPFoundation

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("inited") private var inited = false
    @AppStorage("kor") private var koreanSelection: KoreanSubjects = .easy
    @AppStorage("math") private var mathSelection: MathSubjects = .probStat
    @AppStorage("tamgu1") private var tamgu1Selection: TamguSubjects = .ethics1
    @AppStorage("tamgu2") private var tamgu2Selection: TamguSubjects = .societyCulture
    @AppStorage("backup_on_next_launch") private var shouldBackupNow = false
    @AppStorage("enable_sync") private var prefEnableSync = true
    @AppStorage("enable_background_sync") private var prefEnableBgSync = false
    @Query(sort: \Korean.date, order: .forward) private var korean: [Korean]
    @Query(sort: \Math.date, order: .forward) private var math: [Math]
    @Query(sort: \MathHalf.date, order: .forward) private var math_half: [MathHalf]
    @Query(sort: \Tamgu1.date, order: .forward) private var tamgu1: [Tamgu1]
    @Query(sort: \Tamgu2.date, order: .forward) private var tamgu2: [Tamgu2]
    @State private var selectedTab: Tabs = .kor
    @State private var showOnboarding = false
    
    enum Tabs: String, Identifiable, Hashable, Equatable {
        case kor = "국어"
        case math = "수학"
        case mathHalf = "수학(하프)"
        case tamgu1 = "탐구 1"
        case tamgu2 = "탐구 2"
        
        var id: Tabs { self }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(Tabs.kor.rawValue, systemImage: "text.page", value: .kor) {
                KoreanView()
            }
            Tab(Tabs.math.rawValue, systemImage: "function", value: .math) {
                MathView()
            }
            Tab(Tabs.mathHalf.rawValue, systemImage: "divide", value: .mathHalf) {
                MathHalfView()
            }
            Tab(Tabs.tamgu1.rawValue, systemImage: "flask", value: .tamgu1) {
                Tamgu1View()
            }
            Tab(Tabs.tamgu2.rawValue, systemImage: "flask", value: .tamgu2) {
                Tamgu2View()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .navigationTitle(selectedTab.rawValue)
        .sheet(isPresented: $showOnboarding) {
            OnboardingModalView()
                .interactiveDismissDisabled()
        }
        .onAppear {
            checkInitStatus()
            checkBackupStatus()
            if prefEnableBgSync && !prefEnableSync {
                prefEnableBgSync = false
            }
        }
        .onChange(of: inited) { _, _ in
            checkInitStatus()
        }
        .task {
            await SyncManager.shared.performSync(modelContext: modelContext)
        }
    }
    private func checkInitStatus() {
        if !inited {
            showOnboarding = true
        } else {
            showOnboarding = false
        }
    }
    private func checkBackupStatus() {
        if shouldBackupNow {
            let timestamp = Int(Date.now.timeIntervalSince1970)
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent("backup_\(timestamp)").appendingPathComponent("Payload")
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                
                let korUrl = directory.appendingPathComponent("kor.plist")
                let korData = try encoder.encode(korean.map { $0.toDTO() })
                try korData.write(to: korUrl)
                
                let mathUrl = directory.appendingPathComponent("math.plist")
                let mathData = try encoder.encode(math.map { $0.toDTO() })
                try mathData.write(to: mathUrl)
                
                let mathHalfUrl = directory.appendingPathComponent("mathHalf.plist")
                let mathHalfData = try encoder.encode(math_half.map { $0.toDTO() })
                try mathHalfData.write(to: mathHalfUrl)
                
                let tamgu1Url = directory.appendingPathComponent("tamgu1.plist")
                let tamgu1Data = try encoder.encode(tamgu1.map { $0.toDTO() })
                try tamgu1Data.write(to: tamgu1Url)
                
                let tamgu2Url = directory.appendingPathComponent("tamgu2.plist")
                let tamgu2Data = try encoder.encode(tamgu2.map { $0.toDTO() })
                try tamgu2Data.write(to: tamgu2Url)
                
                let destination = FileManager.default.temporaryDirectory.appendingPathComponent("backup_\(timestamp).zip")
                try FileManager.default.zipItem(at: directory, to: destination, shouldKeepParent: true, compressionMethod: .deflate)
                let activityVC = UIActivityViewController(activityItems: [destination], applicationActivities: nil)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    
                    if let popoverController = activityVC.popoverPresentationController {
                        popoverController.sourceView = rootVC.view
                        popoverController.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                        popoverController.permittedArrowDirections = []
                    }
                    
                    rootVC.present(activityVC, animated: true, completion: nil)
                }
                shouldBackupNow = false
            } catch { print(error) }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Korean.self, Math.self, MathHalf.self, Tamgu1.self, Tamgu2.self], inMemory: true)
}
