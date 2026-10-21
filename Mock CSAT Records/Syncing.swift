//
//  Syncing.swift
//  Mock CSAT Records
//
//  Created by Seongwon Min on 8/8/26.
//

import Foundation
import Combine
import SwiftData
import CryptoKit
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class SyncManager: ObservableObject {
    static let shared = SyncManager()
    static let dummyDomain = "mockcsatrecords.com"
    
    @Published var isSyncing: Bool = false
    @Published var lastSyncError: String?
    
    private let defaults = UserDefaults.standard
        
    private enum Keys {
        static let lastUpdated = "lastUpdated"
        static let lastSynced = "lastSynced"
        static let prefLastSynced = "pref_last_synced"
        static let prefEnableSync = "enable_sync"
        static let prefEnableBgSync = "enable_background_sync"
    }
    var lastUpdated: Date {
        get {
            return defaults.object(forKey: Keys.lastUpdated) as? Date ?? Date(timeIntervalSince1970: 0.0)
        }
        set {
            objectWillChange.send()
            defaults.set(newValue, forKey: Keys.lastUpdated)
        }
    }
    var lastSynced: Date {
        get {
            return defaults.object(forKey: Keys.lastSynced) as? Date ?? Date(timeIntervalSince1970: 0.0)
        }
        set {
            objectWillChange.send()
            defaults.set(newValue, forKey: Keys.lastSynced)
            defaults.set(newValue.formatted(date: .abbreviated, time: .standard), forKey: Keys.prefLastSynced)
        }
    }
    var prefEnableSync: Bool {
        get {
            return defaults.object(forKey: Keys.prefEnableSync) as? Bool ?? true
        }
        set {
            objectWillChange.send()
            defaults.set(newValue, forKey: Keys.prefEnableSync)
        }
    }
    
    var prefEnableBgSync: Bool {
        get {
            return defaults.object(forKey: Keys.prefEnableBgSync) as? Bool ?? false
        }
        set {
            objectWillChange.send()
            defaults.set(newValue, forKey: Keys.prefEnableBgSync)
        }
    }
    
    private let db = Firestore.firestore()
    private let keychain = KeychainHelper.shared
    private var uid: String = ""
    
    private init() {}
    
    @discardableResult
    private func ensureAuthenticated() async throws -> String {
        if let currentUID = Auth.auth().currentUser?.uid {
            return currentUID
        }
        if let (savedEmail, savedPassword) = try? keychain.getFirestoreAuth() {
            do {
                let authResult = try await Auth.auth().signIn(withEmail: savedEmail, password: savedPassword)
                return authResult.user.uid
            } catch {
                print("Login Failed: \(error)")
            }
        }
        
        let newUUID = UUID().uuidString.lowercased()
        let dummyEmail = "\(newUUID)@\(SyncManager.dummyDomain)"
        let dummyPassword = "\(UUID().uuidString)-\(UUID().uuidString)"
        
        let authResult = try await Auth.auth().createUser(withEmail: dummyEmail, password: dummyPassword)
        let newUID = authResult.user.uid
        
        try keychain.saveFirestoreAuth(email: dummyEmail, password: dummyPassword)
        
        return newUID
    }
    
    func performSync(modelContext: ModelContext) async {
        guard !isSyncing else { return }
        isSyncing = true
        lastSyncError = nil
        
        defer { isSyncing = false }
        
        if prefEnableSync {
            
            do {
                self.uid = try await self.ensureAuthenticated()
                let encryptionKey = try keychain.getSymmetricKey()
                
                let userDocRef = db.collection("users").document(self.uid).collection("records")
                
                let syncStartTime = Date.now
                
                try await pullRemoteChangesToLocal(modelContext: modelContext, targetCollection: userDocRef, key: encryptionKey)
                
                try await pushLocalChangesToRemote(modelContext: modelContext, targetCollection: userDocRef, key: encryptionKey)
                
                try modelContext.save()
                
                lastSynced = syncStartTime
                print("Successfully synced at \(syncStartTime)")
                
            } catch {
                self.lastSyncError = error.localizedDescription
                print("Sync failed: \(error)")
            }
        }
    }
    
    private func fetchRecords<T: CloudSyncable>(
        for type: T.Type,
        in context: ModelContext
    ) throws -> [T] {
        let fetchDescriptor = FetchDescriptor<T>()
        let records = try context.fetch(fetchDescriptor)
        return records.filter({ $0.syncStatus != .synced })
    }
    
    private func pushLocalChangesToRemote(
        modelContext: ModelContext,
        targetCollection: CollectionReference,
        key: SymmetricKey
    ) async throws {
        let subjectTypes: [any CloudSyncable.Type] = [
            Korean.self,
            Math.self,
            MathHalf.self,
            Tamgu1.self,
            Tamgu2.self
        ]

        var allRecords: [any CloudSyncable] = []

        for subjectType in subjectTypes {
            let records = try fetchRecords(for: subjectType, in: modelContext)
            allRecords.append(contentsOf: records)
        }
        
        let batchSize = 500
        let chunks = stride(from: 0, to: allRecords.count, by: batchSize).map {
            Array(allRecords[$0..<min($0 + batchSize, allRecords.count)])
        }
        
        for chunk in chunks {
            let batch = db.batch()
            for record in chunk {
                let cloudDTO = try record.toCloudDTO(key: key)
                let docRef = targetCollection.document(cloudDTO.id)
                batch.setData(cloudDTO.toDictionary(), forDocument: docRef, merge: true)
            }
            try await batch.commit()
            for record in chunk {
                record.syncStatus = .synced
            }
        }
    }
    
    private func pullRemoteChangesToLocal(
        modelContext: ModelContext,
        targetCollection: CollectionReference,
        key: SymmetricKey
    ) async throws {
        let snapshot = try await targetCollection.whereField("lastSynced", isGreaterThan: Timestamp(date: lastSynced)).getDocuments()
        // let snapshot = try await targetCollection.getDocuments()
        
        print("\(snapshot.documents.count) records downloaded")
        
        for document in snapshot.documents {
            let data = document.data()
            guard let idStr = data["id"] as? String,
                  let recordID = UUID(uuidString: idStr),
                  let subjectStr = data["subject"] as? String,
                  let subject = SubjectType(rawValue: subjectStr),
                  let lastUpdated = (data["lastUpdated"] as? Timestamp)?.dateValue(),
                  let encryptedPayload = data["payload"] as? String,
                  let isDeleted = data["isDeleted"] as? Bool else {
                continue
            }
            
            guard let payloadData = Data(base64Encoded: encryptedPayload),
                  let sealedBox = try? AES.GCM.SealedBox(combined: payloadData),
                  let decryptedData = try? AES.GCM.open(sealedBox, using: key),
                  let payload = try? JSONDecoder().decode(SyncPayload.self, from: decryptedData) else {
                print("Failed to decrypt record: \(idStr)")
                continue
            }
            
            switch subject {
            case .kor:
                try syncKoreanRecord(
                    modelContext: modelContext,
                    id: recordID,
                    lastUpdated: lastUpdated,
                    payload: payload,
                    isDeleted: isDeleted
                )
                break
            case .math:
                try syncMathRecord(
                    modelContext: modelContext,
                    id: recordID,
                    lastUpdated: lastUpdated,
                    payload: payload,
                    isDeleted: isDeleted
                )
                break
            case .mathHalf:
                try syncMathHalfRecord(
                    modelContext: modelContext,
                    id: recordID,
                    lastUpdated: lastUpdated,
                    payload: payload,
                    isDeleted: isDeleted
                )
                break
            case .tamgu1:
                try syncTamgu1Record(
                    modelContext: modelContext,
                    id: recordID,
                    lastUpdated: lastUpdated,
                    payload: payload,
                    isDeleted: isDeleted
                )
                break
            case .tamgu2:
                try syncTamgu2Record(
                    modelContext: modelContext,
                    id: recordID,
                    lastUpdated: lastUpdated,
                    payload: payload,
                    isDeleted: isDeleted
                )
                break
            }
        }
    }
    
    private func syncKoreanRecord(
        modelContext: ModelContext,
        id: UUID,
        lastUpdated: Date,
        payload: SyncPayload,
        isDeleted: Bool
    ) throws {
        let migrateStatus: String = SyncStatus.migrate.rawValue
        var fetchDescriptor = FetchDescriptor<Korean>()
        let existingRecords = try modelContext.fetch(fetchDescriptor).filter { ($0.syncStatusRawValue != migrateStatus && $0.id == id) || ($0.syncStatusRawValue == migrateStatus && $0.name == payload.name) }
        
        if let existing = existingRecords.first {
            if existing.lastUpdated < lastUpdated {
                existing.lastUpdated = lastUpdated
                if isDeleted {
                    existing.isDeleted = true
                    existing.syncStatus = .synced
                } else {
                    existing.name = payload.name
                    existing.date = payload.date
                    existing.time = payload.time
                    if payload.scores.count == 3 {
                        existing.reading_score = payload.scores[0]
                        existing.literature_score = payload.scores[1]
                        existing.selection_score = payload.scores[2]
                    }
                    if payload.wrongs.count == 3 {
                        existing.reading_wrong = payload.wrongs[0]
                        existing.literature_wrong = payload.wrongs[1]
                        existing.selection_wrong = payload.wrongs[2]
                    }
                    existing.reason = payload.reason
                    existing.syncStatus = .synced
                }
            }
        } else if !isDeleted {
            let newData = Korean(
                id: id,
                syncStatus: .synced,
                lastUpdated: lastUpdated,
                name: payload.name,
                date: payload.date,
                time: payload.time,
                reading_score: payload.scores.element(at: 0) ?? 0,
                literature_score: payload.scores.element(at: 1) ?? 0,
                selection_score: payload.scores.element(at: 2) ?? 0,
                reading_wrong: payload.wrongs.element(at: 0) ?? "",
                literature_wrong: payload.wrongs.element(at: 1) ?? "",
                selection_wrong: payload.wrongs.element(at: 2) ?? "",
                reason: payload.reason
            )
            modelContext.insert(newData)
        }
    }
    
    private func syncMathRecord(
        modelContext: ModelContext,
        id: UUID,
        lastUpdated: Date,
        payload: SyncPayload,
        isDeleted: Bool
    ) throws {
        let migrateStatus: String = SyncStatus.migrate.rawValue
        var fetchDescriptor = FetchDescriptor<Math>()
        
        let existingRecords = try modelContext.fetch(fetchDescriptor).filter { ($0.syncStatusRawValue != migrateStatus && $0.id == id) || ($0.syncStatusRawValue == migrateStatus && $0.name == payload.name) }
        
        if let existing = existingRecords.first {
            if existing.lastUpdated < lastUpdated {
                existing.lastUpdated = lastUpdated
                if isDeleted {
                    existing.isDeleted = true
                    existing.syncStatus = .synced
                } else {
                    existing.name = payload.name
                    existing.date = payload.date
                    existing.time = payload.time
                    if payload.scores.count == 2 {
                        existing.common_score = payload.scores[0]
                        existing.selection_score = payload.scores[1]
                    }
                    if payload.wrongs.count == 2 {
                        existing.common_wrong = payload.wrongs[0]
                        existing.selection_wrong = payload.wrongs[1]
                    }
                    existing.reason = payload.reason
                    existing.syncStatus = .synced
                }
            }
        } else if !isDeleted {
            let newData = Math(
                id: id,
                syncStatus: .synced,
                lastUpdated: lastUpdated,
                name: payload.name,
                date: payload.date,
                time: payload.time,
                common_score: payload.scores.element(at: 0) ?? 0,
                selection_score: payload.scores.element(at: 1) ?? 0,
                common_wrong: payload.wrongs.element(at: 0) ?? "",
                selection_wrong: payload.wrongs.element(at: 1) ?? "",
                reason: payload.reason
            )
            modelContext.insert(newData)
        }
    }
    
    private func syncMathHalfRecord(
        modelContext: ModelContext,
        id: UUID,
        lastUpdated: Date,
        payload: SyncPayload,
        isDeleted: Bool
    ) throws {
        let migrateStatus: String = SyncStatus.migrate.rawValue
        var fetchDescriptor = FetchDescriptor<MathHalf>()
        
        let existingRecords = try modelContext.fetch(fetchDescriptor).filter { ($0.syncStatusRawValue != migrateStatus && $0.id == id) || ($0.syncStatusRawValue == migrateStatus && $0.name == payload.name) }
        
        if let existing = existingRecords.first {
            if existing.lastUpdated < lastUpdated {
                existing.lastUpdated = lastUpdated
                if isDeleted {
                    existing.isDeleted = true
                    existing.syncStatus = .synced
                } else {
                    existing.name = payload.name
                    existing.date = payload.date
                    existing.time = payload.time
                    if payload.scores.count == 2 {
                        existing.common_score = payload.scores[0]
                        existing.selection_score = payload.scores[1]
                    }
                    if payload.wrongs.count == 2 {
                        existing.common_wrong = payload.wrongs[0]
                        existing.selection_wrong = payload.wrongs[1]
                    }
                    existing.reason = payload.reason
                    existing.syncStatus = .synced
                }
            }
        } else if !isDeleted {
            let newData = MathHalf(
                id: id,
                syncStatus: .synced,
                lastUpdated: lastUpdated,
                name: payload.name,
                date: payload.date,
                time: payload.time,
                common_score: payload.scores.element(at: 0) ?? 0,
                selection_score: payload.scores.element(at: 1) ?? 0,
                common_wrong: payload.wrongs.element(at: 0) ?? "",
                selection_wrong: payload.wrongs.element(at: 1) ?? "",
                reason: payload.reason
            )
            modelContext.insert(newData)
        }
    }
    
    private func syncTamgu1Record(
        modelContext: ModelContext,
        id: UUID,
        lastUpdated: Date,
        payload: SyncPayload,
        isDeleted: Bool
    ) throws {
        let migrateStatus: String = SyncStatus.migrate.rawValue
        var fetchDescriptor = FetchDescriptor<Tamgu1>()
        
        let existingRecords = try modelContext.fetch(fetchDescriptor).filter { ($0.syncStatusRawValue != migrateStatus && $0.id == id) || ($0.syncStatusRawValue == migrateStatus && $0.name == payload.name) }
        
        if let existing = existingRecords.first {
            if existing.lastUpdated < lastUpdated {
                existing.lastUpdated = lastUpdated
                if isDeleted {
                    existing.isDeleted = true
                    existing.syncStatus = .synced
                } else {
                    existing.name = payload.name
                    existing.date = payload.date
                    existing.time = payload.time
                    if payload.scores.count == 1 {
                        existing.score = payload.scores[0]
                    }
                    if payload.wrongs.count == 1 {
                        existing.wrong = payload.wrongs[0]
                    }
                    existing.reason = payload.reason
                    existing.syncStatus = .synced
                }
            }
        } else if !isDeleted {
            let newData = Tamgu1(
                id: id,
                syncStatus: .synced,
                lastUpdated: lastUpdated,
                name: payload.name,
                date: payload.date,
                time: payload.time,
                score: payload.scores.element(at: 0) ?? 0,
                wrong: payload.wrongs.element(at: 0) ?? "",
                reason: payload.reason
            )
            modelContext.insert(newData)
        }
    }
    
    private func syncTamgu2Record(
        modelContext: ModelContext,
        id: UUID,
        lastUpdated: Date,
        payload: SyncPayload,
        isDeleted: Bool
    ) throws {
        let migrateStatus: String = SyncStatus.migrate.rawValue
        var fetchDescriptor = FetchDescriptor<Tamgu2>()
        
        let existingRecords = try modelContext.fetch(fetchDescriptor).filter { ($0.syncStatusRawValue != migrateStatus && $0.id == id) || ($0.syncStatusRawValue == migrateStatus && $0.name == payload.name) }
        
        if let existing = existingRecords.first {
            if existing.lastUpdated < lastUpdated {
                existing.lastUpdated = lastUpdated
                if isDeleted {
                    existing.isDeleted = true
                    existing.syncStatus = .synced
                } else {
                    existing.name = payload.name
                    existing.date = payload.date
                    existing.time = payload.time
                    if payload.scores.count == 1 {
                        existing.score = payload.scores[0]
                    }
                    if payload.wrongs.count == 1 {
                        existing.wrong = payload.wrongs[0]
                    }
                    existing.reason = payload.reason
                    existing.syncStatus = .synced
                }
            }
        } else if !isDeleted {
            let newData = Tamgu2(
                id: id,
                syncStatus: .synced,
                lastUpdated: lastUpdated,
                name: payload.name,
                date: payload.date,
                time: payload.time,
                score: payload.scores.element(at: 0) ?? 0,
                wrong: payload.wrongs.element(at: 0) ?? "",
                reason: payload.reason
            )
            modelContext.insert(newData)
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
    func element(at index: Int) -> Element? {
        return self[safe: index]
    }
}
