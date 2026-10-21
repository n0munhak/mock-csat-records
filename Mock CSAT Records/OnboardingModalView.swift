//
//  OnboardingModalView.swift
//  Mock CSAT Records
//
//  Created by Seongwon Min on 7/3/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import ZIPFoundation
import FirebaseAuth

struct OnboardingModalView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("inited") private var inited = false
    @AppStorage("enable_sync") private var prefEnableSync = true
    @AppStorage("lastUpdated") private var lastUpdated: Date = Date(timeIntervalSince1970: 0.0)
    @AppStorage("lastSynced") private var lastSynced: Date = Date(timeIntervalSince1970: 0.0)
    @AppStorage("kor") private var koreanSelection: KoreanSubjects = .easy
    @AppStorage("math") private var mathSelection: MathSubjects = .probStat
    @AppStorage("tamgu1") private var tamgu1Selection: TamguSubjects = .ethics1
    @AppStorage("tamgu2") private var tamgu2Selection: TamguSubjects = .societyCulture
    @State private var showPicker = false
    @State private var backupFileMessage: String = "선택된 파일 없음"
    @State private var hasBackup = false
    @State private var backupFileLocation: URL? = nil
    @State private var restoreSync = false
    @State private var syncEmail = ""
    @State private var syncPassword = ""
    @State private var syncKey = ""
    
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Form {
                    Section(header: Text("선택 과목")) {
                        Picker("1. 국어", selection: $koreanSelection) {
                            ForEach(KoreanSubjects.allCases, id: \.self) { Text($0.rawValue) }
                        }
                        .pickerStyle(.menu)
                        Picker("2. 수학", selection: $mathSelection) {
                            ForEach(MathSubjects.allCases, id: \.self) { Text($0.rawValue) }
                        }
                        .pickerStyle(.menu)
                        Picker("4-2. 탐구 제1선택", selection: $tamgu1Selection) {
                            ForEach(TamguSubjects.allCases, id: \.self) { Text($0.rawValue) }
                        }
                        .pickerStyle(.menu)
                        Picker("4-3. 탐구 제2선택", selection: $tamgu2Selection) {
                            ForEach(TamguSubjects.allCases, id: \.self) { Text($0.rawValue) }
                        }
                        .pickerStyle(.menu)
                    }
                    Section(header: Text("백업")) {
                        HStack {
                            Text("백업 파일")
                            Spacer()
                            Text(backupFileMessage)
                                .foregroundColor(.secondary)
                        }
                        Button("백업 불러오기") {
                            showPicker = true
                        }
                        .fileImporter(isPresented: $showPicker, allowedContentTypes: [.zip]) { result in
                            do {
                                switch result {
                                case .success(let url):
                                    let gainedAccess = url.startAccessingSecurityScopedResource()
                                    defer {
                                        if gainedAccess { url.stopAccessingSecurityScopedResource() }
                                    }
                                    
                                    if gainedAccess {
                                        backupFileMessage = url.lastPathComponent
                                        let timestamp = Int(Date.now.timeIntervalSince1970)
                                        let cwd = FileManager.default.temporaryDirectory.appendingPathComponent("restore_\(timestamp)")
                                        let payloadDir = cwd.appendingPathComponent("Payload")
                                        try FileManager.default.createDirectory(at: cwd, withIntermediateDirectories: true)
                                        try FileManager.default.copyItem(at: url, to: cwd.appendingPathComponent("archive.zip"))
                                        try FileManager.default.unzipItem(at: cwd.appendingPathComponent("archive.zip"), to: cwd)
                                        hasBackup = true
                                        backupFileLocation = payloadDir
                                    } else {
                                        backupFileMessage = "에러: 권한 없음"
                                    }
                                    
                                case .failure(let error):
                                    backupFileMessage = "에러: \(error.localizedDescription)"
                                }
                            } catch {
                                print(error)
                            }
                        }
                    }
                    Section(header: Text("동기화")) {
                        Toggle(isOn: $restoreSync) { Text("동기화 계정 불러오기(고급)") }
                        if restoreSync {
                            LabeledContent("동기화 ID") {
                                TextField("입력", text: $syncEmail)
                                    .multilineTextAlignment(.trailing)
                            }
                            LabeledContent("동기화 비밀번호") {
                                TextField("입력", text: $syncPassword)
                                    .multilineTextAlignment(.trailing)
                            }
                            LabeledContent("동기화 키") {
                                TextField("입력", text: $syncKey)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                }
                
                Button(action: saveSettings) {
                    Text("완료")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .padding()
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("초기 설정")
        }
    }
    
    private func saveSettings() {
        do {
            if restoreSync {
                try KeychainHelper.shared.saveFirestoreAuth(email: "\(syncEmail)", password: "\(syncPassword)")
                try KeychainHelper.shared.setSymmetricKey(b64EncodedKey: "\(syncKey)")
                lastUpdated = Date(timeIntervalSince1970: 0)
                lastSynced = Date(timeIntervalSince1970: 0)
                try Auth.auth().signOut()
            }
            if hasBackup {
                let decoder = PropertyListDecoder()
                guard let backupFileLocation = backupFileLocation else { return }
                
                let korData = try Data(contentsOf: backupFileLocation.appendingPathComponent("kor.plist"))
                let mathData = try Data(contentsOf: backupFileLocation.appendingPathComponent("math.plist"))
                let mathHalfData = try Data(contentsOf: backupFileLocation.appendingPathComponent("mathHalf.plist"))
                let tamgu1Data = try Data(contentsOf: backupFileLocation.appendingPathComponent("tamgu1.plist"))
                let tamgu2Data = try Data(contentsOf: backupFileLocation.appendingPathComponent("tamgu2.plist"))
                
                var kor: [Korean] = []
                var math: [Math] = []
                var mathHalf: [MathHalf] = []
                var tamgu1: [Tamgu1] = []
                var tamgu2: [Tamgu2] = []
                
                do {
                    kor = try decoder.decode([OldKoreanBackupDTO].self, from: korData).map { $0.toModel() }
                    math = try decoder.decode([MathBackupDTO].self, from: mathData).map { $0.toModel() }
                    mathHalf = try decoder.decode([MathHalfBackupDTO].self, from: mathHalfData).map { $0.toModel() }
                    tamgu1 = try decoder.decode([Tamgu1BackupDTO].self, from: tamgu1Data).map { $0.toModel() }
                    tamgu2 = try decoder.decode([Tamgu2BackupDTO].self, from: tamgu2Data).map { $0.toModel() }
                } catch {
                    do {
                        kor = try decoder.decode([OldKoreanBackupDTO].self, from: korData).map { $0.toModel() }
                        math = try decoder.decode([OldMathBackupDTO].self, from: mathData).map { $0.toModel() }
                        mathHalf = try decoder.decode([OldMathHalfBackupDTO].self, from: mathHalfData).map { $0.toModel() }
                        tamgu1 = try decoder.decode([OldTamgu1BackupDTO].self, from: tamgu1Data).map { $0.toModel() }
                        tamgu2 = try decoder.decode([OldTamgu2BackupDTO].self, from: tamgu2Data).map { $0.toModel() }
                    } catch {
                        print(error)
                    }
                }
                
                try modelContext.delete(model: Korean.self)
                try modelContext.delete(model: Math.self)
                try modelContext.delete(model: MathHalf.self)
                try modelContext.delete(model: Tamgu1.self)
                try modelContext.delete(model: Tamgu2.self)
                
                let date = Date.now
                
                kor.forEach { entry in
                    entry.lastUpdated = date
                    modelContext.insert(entry)
                }
                math.forEach { entry in
                    entry.lastUpdated = date
                    modelContext.insert(entry)
                }
                mathHalf.forEach { entry in
                    entry.lastUpdated = date
                    modelContext.insert(entry)
                }
                tamgu1.forEach { entry in
                    entry.lastUpdated = date
                    modelContext.insert(entry)
                }
                tamgu2.forEach { entry in
                    entry.lastUpdated = date
                    modelContext.insert(entry)
                }
                
                lastUpdated = date
            }
            
            prefEnableSync = true
            
            Task {
                await SyncManager.shared.performSync(modelContext: modelContext)
            }
            inited.toggle()
        } catch {
            print(error)
        }
    }
}
