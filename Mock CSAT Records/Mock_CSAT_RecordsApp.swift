//
//  Mock_CSAT_RecordsApp.swift
//  Mock CSAT Records
//
//  Created by Seongwon Min on 7/2/26.
//

import SwiftUI
import UIKit
import SwiftData
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct Mock_CSAT_RecordsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) private var scenePhase
    let container = SharedModelContainer.container
    
    
    init() {
        BackgroundSyncManager.shared.registerBackgroundTask()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                BackgroundSyncManager.shared.scheduleAppRefresh()
            }
        }
    }
}
