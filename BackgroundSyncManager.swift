//
//  BackgroundSyncManager.swift
//  Mock CSAT Records
//
//  Created by Seongwon Min on 8/8/26.
//


import Foundation
import BackgroundTasks
import SwiftData

@MainActor
final class BackgroundSyncManager {
    static let shared = BackgroundSyncManager()
    
    let taskIdentifier = "com.nomunhak.Mock-CSAT-Records.sync"
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { [weak self] task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            Task {
                await self?.handleAppRefresh(task: refreshTask)
            }
        }
    }
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print(error)
        }
    }
    
    private func handleAppRefresh(task: BGAppRefreshTask) async {
        if (defaults.object(forKey: "enable_background_sync") as? Bool ?? false) == true {
            scheduleAppRefresh()
            
            let syncTask = Task { @MainActor in
                let context = SharedModelContainer.container.mainContext
                await SyncManager.shared.performSync(modelContext: context)
            }
            
            task.expirationHandler = {
                syncTask.cancel()
                task.setTaskCompleted(success: false)
            }
            
            let result = await syncTask.result
            
            switch result {
            case .success:
                task.setTaskCompleted(success: true)
            case .failure:
                task.setTaskCompleted(success: false)
            }
        } else {
            task.setTaskCompleted(success: true)
        }
    }
}
