import Foundation
import UIKit

struct GameRecord: Codable, Identifiable {
    let id = UUID()
    let difficulty: Difficulty
    let errorCount: Int
    let hintCount: Int
    let elapsedTime: Int
    let date: Date
    let puzzleId: String?
    
    enum CodingKeys: String, CodingKey {
        case difficulty
        case errorCount
        case hintCount
        case elapsedTime
        case date
        case puzzleId
    }
    
    init(difficulty: Difficulty, errorCount: Int, hintCount: Int, elapsedTime: Int, date: Date, puzzleId: String? = nil) {
        self.difficulty = difficulty
        self.errorCount = errorCount
        self.hintCount = hintCount
        self.elapsedTime = elapsedTime
        self.date = date
        self.puzzleId = puzzleId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        difficulty = try container.decode(Difficulty.self, forKey: .difficulty)
        errorCount = try container.decode(Int.self, forKey: .errorCount)
        hintCount = try container.decode(Int.self, forKey: .hintCount)
        elapsedTime = try container.decode(Int.self, forKey: .elapsedTime)
        date = try container.decode(Date.self, forKey: .date)
        puzzleId = try container.decodeIfPresent(String.self, forKey: .puzzleId)
    }
    
    var formattedTime: String {
        let minutes = elapsedTime / 60
        let seconds = elapsedTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var difficultyName: String {
        switch difficulty {
        case .easy: return "简单"
        case .medium: return "中等"
        case .hard: return "困难"
        }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    // Calculate score (fewer errors, fewer hints, shorter time = higher score)
    var score: Int {
        let baseScore = difficulty == .hard ? 300 : difficulty == .medium ? 200 : 100
        let timeBonus = max(0, 300 - elapsedTime)
        let errorPenalty = errorCount * 10
        let hintPenalty = hintCount * 5
        return baseScore + timeBonus - errorPenalty - hintPenalty
    }
}

struct UserInfo: Codable {
    var userId: String
    var username: String
    
    static func generateUserId() -> String {
        // 根据设备信息生成唯一ID
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        return deviceId
    }
}

class GameRecordsManager: ObservableObject {
    @Published var records: [GameRecord] = []
    @Published var userInfo: UserInfo
    
    init() {
        // Load user info
        if let data = UserDefaults.standard.data(forKey: GameConfig.Settings.userInfoKey),
           let info = try? JSONDecoder().decode(UserInfo.self, from: data) {
            userInfo = info
        } else {
            userInfo = UserInfo(userId: UserInfo.generateUserId(), username: "玩家")
            saveUserInfo()
        }
        
        // Load game records
        loadRecords()
    }
    
    func addRecord(_ record: GameRecord) {
        records.append(record)
        // Sort by score, keep top 20 records
        records.sort { $0.score > $1.score }
        if records.count > 20 {
            records = Array(records.prefix(20))
        }
        saveRecords()
    }
    
    func updateUsername(_ username: String) {
        userInfo.username = username
        saveUserInfo()
    }
    
    private func saveRecords() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: GameConfig.Settings.recordsKey)
        }
    }
    
    private func loadRecords() {
        if let data = UserDefaults.standard.data(forKey: GameConfig.Settings.recordsKey),
           let savedRecords = try? JSONDecoder().decode([GameRecord].self, from: data) {
            records = savedRecords
        }
    }
    
    private func saveUserInfo() {
        if let data = try? JSONEncoder().encode(userInfo) {
            UserDefaults.standard.set(data, forKey: GameConfig.Settings.userInfoKey)
        }
    }
    
    func getRankings() -> [GameRecord] {
        return records.sorted { $0.score > $1.score }
    }
}
