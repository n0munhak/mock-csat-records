//
//  Item.swift
//  Mock CSAT Records
//
//  Created by Seongwon Min on 7/2/26.
//

import Foundation
import SwiftData
import CryptoKit
import FirebaseFirestore

enum SubjectType: String, Codable {
    case kor, math, mathHalf, tamgu1, tamgu2
}

nonisolated struct SyncPayload: Codable {
    var subject: SubjectType
    var name: String
    var date: Date
    var time: Int
    var scores: [Int]
    var wrongs: [String]
    var reason: String
}

struct CloudRecordDTO {
    var id: String
    var subject: String
    var lastUpdated: Date
    var isDeleted: Bool
    var payload: String
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "subject": subject,
            "lastUpdated": lastUpdated,
            "isDeleted": isDeleted,
            "payload": payload,
            "lastSynced": FieldValue.serverTimestamp()
        ]
    }
}

enum SyncStatus: String, Codable {
    case migrate
    case local
    case synced
}

protocol CloudSyncable: PersistentModel {
    var id: UUID { get set }
    var syncStatus: SyncStatus { get set }
    var syncStatusRawValue: String { get }
    var lastUpdated: Date { get set }
    var isDeleted: Bool { get }
    func toCloudPayload() -> SyncPayload
    func toCloudDTO(key: SymmetricKey) throws -> CloudRecordDTO
}

extension CloudSyncable {
    var syncStatusRawValue: String {
        return syncStatus.rawValue
    }
    
    func toCloudDTO(key: SymmetricKey) throws -> CloudRecordDTO {
        let payload = self.toCloudPayload()
        let jsonData = try JSONEncoder().encode(payload)
        
        let sealedBox = try AES.GCM.seal(jsonData, using: key)
        guard let encryptedBase64 = sealedBox.combined?.base64EncodedString() else {
            throw NSError(domain: "EncryptionError", code: -1)
        }
        
        return CloudRecordDTO(
            id: self.id.uuidString,
            subject: payload.subject.rawValue,
            lastUpdated: self.lastUpdated,
            isDeleted: self.isDeleted,
            payload: encryptedBase64
        )
    }
}

@Model
final class Korean: CloudSyncable {
    var id: UUID = UUID()
    var syncStatus: SyncStatus = SyncStatus.migrate
    var lastUpdatedInternal: Date = Date.distantPast
    var lastUpdated: Date {
        get {
            return lastUpdatedInternal == Date.distantPast ? date : lastUpdatedInternal
        }
        set {
            lastUpdatedInternal = newValue
        }
    }
    var isDeleted: Bool = false
    var name: String
    var date: Date
    var time: Int
    var reading_score: Int
    var literature_score: Int
    var selection_score: Int
    var reading_wrong: String
    var literature_wrong: String
    var selection_wrong: String
    var reason: String
    
    init(id: UUID = UUID(), syncStatus: SyncStatus = .migrate, lastUpdated: Date? = nil, isDeleted: Bool = false, name: String, date: Date = Date.now, time: Int, reading_score: Int, literature_score: Int, selection_score: Int, reading_wrong: String, literature_wrong: String, selection_wrong: String, reason: String) {
        self.id = id
        self.syncStatus = syncStatus
        self.lastUpdatedInternal = lastUpdated ?? date
        self.isDeleted = isDeleted
        self.name = name
        self.date = date
        self.time = time
        self.reading_score = reading_score
        self.literature_score = literature_score
        self.selection_score = selection_score
        self.reading_wrong = reading_wrong
        self.literature_wrong = literature_wrong
        self.selection_wrong = selection_wrong
        self.reason = reason
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case lastUpdated
        case isDeleted
        case name
        case date
        case time
        case reading_score
        case literature_score
        case selection_score
        case reading_wrong
        case literature_wrong
        case selection_wrong
        case reason
    }
    
    func toDTO() -> KoreanBackupDTO {
        return KoreanBackupDTO(
            id: self.id,
            isDeleted: self.isDeleted,
            name: self.name,
            date: self.date,
            time: self.time,
            reading_score: self.reading_score,
            literature_score: self.literature_score,
            selection_score: self.selection_score,
            reading_wrong: self.reading_wrong,
            literature_wrong: self.literature_wrong,
            selection_wrong: self.selection_wrong,
            reason: self.reason
        )
    }
    
    func toCloudPayload() -> SyncPayload {
        return SyncPayload(
            subject: .kor,
            name: self.name,
            date: self.date,
            time: self.time,
            scores: [self.reading_score, self.literature_score, self.selection_score],
            wrongs: [self.reading_wrong, self.literature_wrong, self.selection_wrong],
            reason: self.reason
        )
    }
}

struct KoreanBackupDTO: Codable {
    var id: UUID
    var isDeleted: Bool
    var name: String
    var date: Date
    var time: Int
    var reading_score: Int
    var literature_score: Int
    var selection_score: Int
    var reading_wrong: String
    var literature_wrong: String
    var selection_wrong: String
    var reason: String
}

extension KoreanBackupDTO {
    func toModel() -> Korean {
        return Korean(
            id: self.id,
            syncStatus: .local,
            isDeleted: self.isDeleted,
            name: self.name,
            date: self.date,
            time: self.time,
            reading_score: self.reading_score,
            literature_score: self.literature_score,
            selection_score: self.selection_score,
            reading_wrong: self.reading_wrong,
            literature_wrong: self.literature_wrong,
            selection_wrong: self.selection_wrong,
            reason: self.reason
        )
    }
}

struct OldKoreanBackupDTO: Codable {
    var name: String
    var date: Date
    var time: Int
    var reading_score: Int
    var literature_score: Int
    var selection_score: Int
    var reading_wrong: String
    var literature_wrong: String
    var selection_wrong: String
    var reason: String
}

extension OldKoreanBackupDTO {
    func toModel() -> Korean {
        return Korean(
            id: UUID(),
            syncStatus: .migrate,
            isDeleted: false,
            name: self.name,
            date: self.date,
            time: self.time,
            reading_score: self.reading_score,
            literature_score: self.literature_score,
            selection_score: self.selection_score,
            reading_wrong: self.reading_wrong,
            literature_wrong: self.literature_wrong,
            selection_wrong: self.selection_wrong,
            reason: self.reason
        )
    }
}

@Model
final class Math: CloudSyncable {
    var id: UUID = UUID()
    var syncStatus: SyncStatus = SyncStatus.migrate
    var lastUpdatedInternal: Date = Date.distantPast
    var lastUpdated: Date {
        get {
            return lastUpdatedInternal == Date.distantPast ? date : lastUpdatedInternal
        }
        set {
            lastUpdatedInternal = newValue
        }
    }
    var isDeleted: Bool = false
    var name: String
    var date: Date
    var time: Int
    var common_score: Int
    var selection_score: Int
    var common_wrong: String
    var selection_wrong: String
    var reason: String
    
    init(id: UUID = UUID(), syncStatus: SyncStatus = .migrate, lastUpdated: Date? = nil, isDeleted: Bool = false, name: String, date: Date = Date.now, time: Int, common_score: Int, selection_score: Int, common_wrong: String, selection_wrong: String, reason: String) {
        self.id = id
        self.syncStatus = syncStatus
        self.lastUpdatedInternal = lastUpdated ?? date
        self.isDeleted = isDeleted
        self.name = name
        self.date = date
        self.time = time
        self.common_score = common_score
        self.selection_score = selection_score
        self.common_wrong = common_wrong
        self.selection_wrong = selection_wrong
        self.reason = reason
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case lastUpdated
        case isDeleted
        case name
        case date
        case time
        case common_score
        case selection_score
        case common_wrong
        case selection_wrong
        case reason
    }
    
    func toDTO() -> MathBackupDTO {
        return MathBackupDTO(
            id: self.id,
            isDeleted: self.isDeleted,
            name: self.name,
            date: self.date,
            time: self.time,
            common_score: self.common_score,
            selection_score: self.selection_score,
            common_wrong: self.common_wrong,
            selection_wrong: self.selection_wrong,
            reason: self.reason
        )
    }
    
    func toCloudPayload() -> SyncPayload {
        return SyncPayload(
            subject: .math,
            name: self.name,
            date: self.date,
            time: self.time,
            scores: [self.common_score, self.selection_score],
            wrongs: [self.common_wrong, self.selection_wrong],
            reason: self.reason
        )
    }
}

struct MathBackupDTO: Codable {
    var id: UUID
    var isDeleted: Bool
    var name: String
    var date: Date
    var time: Int
    var common_score: Int
    var selection_score: Int
    var common_wrong: String
    var selection_wrong: String
    var reason: String
}

extension MathBackupDTO {
    func toModel() -> Math {
        return Math(
            id: self.id,
            syncStatus: .local,
            isDeleted: self.isDeleted,
            name: self.name,
            date: self.date,
            time: self.time,
            common_score: self.common_score,
            selection_score: self.selection_score,
            common_wrong: self.common_wrong,
            selection_wrong: self.selection_wrong,
            reason: self.reason
        )
    }
}

struct OldMathBackupDTO: Codable {
    var name: String
    var date: Date
    var time: Int
    var common_score: Int
    var selection_score: Int
    var common_wrong: String
    var selection_wrong: String
    var reason: String
}

extension OldMathBackupDTO {
    func toModel() -> Math {
        return Math(
            id: UUID(),
            syncStatus: .migrate,
            isDeleted: false,
            name: self.name,
            date: self.date,
            time: self.time,
            common_score: self.common_score,
            selection_score: self.selection_score,
            common_wrong: self.common_wrong,
            selection_wrong: self.selection_wrong,
            reason: self.reason
        )
    }
}

@Model
final class MathHalf: CloudSyncable {
    var id: UUID = UUID()
    var syncStatus: SyncStatus = SyncStatus.migrate
    var lastUpdatedInternal: Date = Date.distantPast
    var lastUpdated: Date {
        get {
            return lastUpdatedInternal == Date.distantPast ? date : lastUpdatedInternal
        }
        set {
            lastUpdatedInternal = newValue
        }
    }
    var isDeleted: Bool = false
    var name: String
    var date: Date
    var time: Int
    var common_score: Int
    var selection_score: Int
    var common_wrong: String
    var selection_wrong: String
    var reason: String
    
    init(id: UUID = UUID(), syncStatus: SyncStatus = .migrate, lastUpdated: Date? = nil, isDeleted: Bool = false, name: String, date: Date = Date.now, time: Int, common_score: Int, selection_score: Int, common_wrong: String, selection_wrong: String, reason: String) {
        self.id = id
        self.syncStatus = syncStatus
        self.lastUpdatedInternal = lastUpdated ?? date
        self.isDeleted = isDeleted
        self.name = name
        self.date = date
        self.time = time
        self.common_score = common_score
        self.selection_score = selection_score
        self.common_wrong = common_wrong
        self.selection_wrong = selection_wrong
        self.reason = reason
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case lastUpdated
        case isDeleted
        case name
        case date
        case time
        case common_score
        case selection_score
        case common_wrong
        case selection_wrong
        case reason
    }
    
    func toDTO() -> MathHalfBackupDTO {
        return MathHalfBackupDTO(
            id: self.id,
            isDeleted: self.isDeleted,
            name: self.name,
            date: self.date,
            time: self.time,
            common_score: self.common_score,
            selection_score: self.selection_score,
            common_wrong: self.common_wrong,
            selection_wrong: self.selection_wrong,
            reason: self.reason
        )
    }
    
    func toCloudPayload() -> SyncPayload {
        return SyncPayload(
            subject: .mathHalf,
            name: self.name,
            date: self.date,
            time: self.time,
            scores: [self.common_score, self.selection_score],
            wrongs: [self.common_wrong, self.selection_wrong],
            reason: self.reason
        )
    }
}

struct MathHalfBackupDTO: Codable {
    var id: UUID
    var isDeleted: Bool
    var name: String
    var date: Date
    var time: Int
    var common_score: Int
    var selection_score: Int
    var common_wrong: String
    var selection_wrong: String
    var reason: String
}

extension MathHalfBackupDTO {
    func toModel() -> MathHalf {
        return MathHalf(
            id: self.id,
            syncStatus: .local,
            isDeleted: self.isDeleted,
            name: self.name,
            date: self.date,
            time: self.time,
            common_score: self.common_score,
            selection_score: self.selection_score,
            common_wrong: self.common_wrong,
            selection_wrong: self.selection_wrong,
            reason: self.reason
        )
    }
}

struct OldMathHalfBackupDTO: Codable {
    var name: String
    var date: Date
    var time: Int
    var common_score: Int
    var selection_score: Int
    var common_wrong: String
    var selection_wrong: String
    var reason: String
}

extension OldMathHalfBackupDTO {
    func toModel() -> MathHalf {
        return MathHalf(
            id: UUID(),
            syncStatus: .migrate,
            isDeleted: false,
            name: self.name,
            date: self.date,
            time: self.time,
            common_score: self.common_score,
            selection_score: self.selection_score,
            common_wrong: self.common_wrong,
            selection_wrong: self.selection_wrong,
            reason: self.reason
        )
    }
}

@Model
final class Tamgu1: CloudSyncable {
    var id: UUID = UUID()
    var syncStatus: SyncStatus = SyncStatus.migrate
    var lastUpdatedInternal: Date = Date.distantPast
    var lastUpdated: Date {
        get {
            return lastUpdatedInternal == Date.distantPast ? date : lastUpdatedInternal
        }
        set {
            lastUpdatedInternal = newValue
        }
    }
    var isDeleted: Bool = false
    var name: String
    var date: Date
    var time: Int
    var score: Int
    var wrong: String
    var reason: String
    
    init(id: UUID = UUID(), syncStatus: SyncStatus = .migrate, lastUpdated: Date? = nil, isDeleted: Bool = false, name: String, date: Date = Date.now, time: Int, score: Int, wrong: String, reason: String) {
        self.id = id
        self.syncStatus = syncStatus
        self.lastUpdatedInternal = lastUpdated ?? date
        self.isDeleted = isDeleted
        self.name = name
        self.date = date
        self.time = time
        self.score = score
        self.wrong = wrong
        self.reason = reason
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case lastUpdated
        case isDeleted
        case name
        case date
        case time
        case score
        case wrong
        case reason
    }
    
    func toDTO() -> Tamgu1BackupDTO {
        return Tamgu1BackupDTO(
            id: self.id,
            isDeleted: self.isDeleted,
            name: self.name,
            date: self.date,
            time: self.time,
            score: self.score,
            wrong: self.wrong,
            reason: self.reason
        )
    }
    
    func toCloudPayload() -> SyncPayload {
        return SyncPayload(
            subject: .tamgu1,
            name: self.name,
            date: self.date,
            time: self.time,
            scores: [self.score],
            wrongs: [self.wrong],
            reason: self.reason
        )
    }
}

struct Tamgu1BackupDTO: Codable {
    var id: UUID
    var isDeleted: Bool
    var name: String
    var date: Date
    var time: Int
    var score: Int
    var wrong: String
    var reason: String
}

extension Tamgu1BackupDTO {
    func toModel() -> Tamgu1 {
        return Tamgu1(
            id: self.id,
            syncStatus: .local,
            isDeleted: self.isDeleted,
            name: self.name,
            date: self.date,
            time: self.time,
            score: self.score,
            wrong: self.wrong,
            reason: self.reason
        )
    }
}

struct OldTamgu1BackupDTO: Codable {
    var name: String
    var date: Date
    var time: Int
    var score: Int
    var wrong: String
    var reason: String
}

extension OldTamgu1BackupDTO {
    func toModel() -> Tamgu1 {
        return Tamgu1(
            id: UUID(),
            syncStatus: .migrate,
            isDeleted: false,
            name: self.name,
            date: self.date,
            time: self.time,
            score: self.score,
            wrong: self.wrong,
            reason: self.reason
        )
    }
}


@Model
final class Tamgu2: CloudSyncable {
    var id: UUID = UUID()
    var syncStatus: SyncStatus = SyncStatus.migrate
    var lastUpdatedInternal: Date = Date.distantPast
    var lastUpdated: Date {
        get {
            return lastUpdatedInternal == Date.distantPast ? date : lastUpdatedInternal
        }
        set {
            lastUpdatedInternal = newValue
        }
    }
    var isDeleted: Bool = false
    var name: String
    var date: Date
    var time: Int
    var score: Int
    var wrong: String
    var reason: String
    
    init(id: UUID = UUID(), syncStatus: SyncStatus = .migrate, lastUpdated: Date? = nil, isDeleted: Bool = false, name: String, date: Date = Date.now, time: Int, score: Int, wrong: String, reason: String) {
        self.id = id
        self.syncStatus = syncStatus
        self.lastUpdatedInternal = lastUpdated ?? date
        self.isDeleted = isDeleted
        self.name = name
        self.date = date
        self.time = time
        self.score = score
        self.wrong = wrong
        self.reason = reason
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case lastUpdated
        case isDeleted
        case name
        case date
        case time
        case score
        case wrong
        case reason
    }
    
    func toDTO() -> Tamgu2BackupDTO {
        return Tamgu2BackupDTO(
            id: self.id,
            isDeleted: self.isDeleted,
            name: self.name,
            date: self.date,
            time: self.time,
            score: self.score,
            wrong: self.wrong,
            reason: self.reason
        )
    }
    
    func toCloudPayload() -> SyncPayload {
        return SyncPayload(
            subject: .tamgu2,
            name: self.name,
            date: self.date,
            time: self.time,
            scores: [self.score],
            wrongs: [self.wrong],
            reason: self.reason
        )
    }
}

struct Tamgu2BackupDTO: Codable {
    var id: UUID
    var isDeleted: Bool
    var name: String
    var date: Date
    var time: Int
    var score: Int
    var wrong: String
    var reason: String
}

extension Tamgu2BackupDTO {
    func toModel() -> Tamgu2 {
        return Tamgu2(
            id: self.id,
            syncStatus: .local,
            isDeleted: self.isDeleted,
            name: self.name,
            date: self.date,
            time: self.time,
            score: self.score,
            wrong: self.wrong,
            reason: self.reason
        )
    }
}

struct OldTamgu2BackupDTO: Codable {
    var name: String
    var date: Date
    var time: Int
    var score: Int
    var wrong: String
    var reason: String
}

extension OldTamgu2BackupDTO {
    func toModel() -> Tamgu2 {
        return Tamgu2(
            id: UUID(),
            syncStatus: .migrate,
            isDeleted: false,
            name: self.name,
            date: self.date,
            time: self.time,
            score: self.score,
            wrong: self.wrong,
            reason: self.reason
        )
    }
}

enum KoreanSubjects: String, CaseIterable, Codable {
    case easy = "화법과 작문"
    case hard = "언어와 매체"
}

enum MathSubjects: String, CaseIterable, Codable {
    case probStat = "확률과 통계"
    case calculus = "미적분"
    case geometry = "기하"
}

enum TamguSubjects: String, CaseIterable, Codable {
    case ethics1 = "생활과 윤리"
    case ethics2 = "윤리와 사상"
    case koreanGeo = "한국지리"
    case worldGeo = "세계지리"
    case eastAsianHist = "동아시아사"
    case worldHist = "세계사"
    case politicsLaws = "정치와 법"
    case economy = "경제"
    case societyCulture = "사회·문화"
    case phy1 = "물리학 I"
    case chem1 = "화학 I"
    case bio1 = "생명과학 I"
    case earth1 = "지구과학 I"
    case phy2 = "물리학 II"
    case chem2 = "화학 II"
    case bio2 = "생명과학 II"
    case earth2 = "지구과학 II"
}
