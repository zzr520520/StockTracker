import Foundation
import SwiftUI

// 四种涨跌状态（一大一小）
enum GridStatus: String, Codable, CaseIterable {
    case bigUp = "大涨"
    case smallUp = "小涨"
    case smallDown = "小跌"
    case bigDown = "大跌"
    
    var color: Color {
        switch self {
        case .bigUp: return Color(red: 0.85, green: 0.1, blue: 0.1)     // 深红
        case .smallUp: return Color(red: 1.0, green: 0.5, blue: 0.5)    // 浅红
        case .smallDown: return Color(red: 0.5, green: 0.85, blue: 0.5) // 浅绿
        case .bigDown: return Color(red: 0.1, green: 0.6, blue: 0.1)    // 深绿
        }
    }
}

// 单行 5 交易日网格数据
struct DailyGridRow: Identifiable, Codable {
    var id = UUID()
    var grid: [GridStatus] // 固定 5 列（周一至周五）
    var score: Double
    
    init(grid: [GridStatus] = Array(repeating: .smallUp, count: 5), score: Double = 0.0) {
        self.grid = grid
        self.score = score
    }
}

// 每周/每日记录模型
struct DailyRecord: Identifiable, Codable {
    // 复合唯一主键：日期_标注
    var id: String { 
        let tag = tagNote.isEmpty ? "DEFAULT" : tagNote
        return "\(dateString)_\(tag)" 
    }
    
    var dateString: String // 格式: yyyy-MM-dd
    var tagNote: String = "" // 顶部右侧标注/股票名称
    var rows: [DailyGridRow]
    
    // 统计大涨与小涨总数
    var totalUpCount: Int {
        var count = 0
        for row in rows {
            for status in row.grid {
                if status == .bigUp || status == .smallUp {
                    count += 1
                }
            }
        }
        return count
    }
    
    // 统计大跌与小跌总数
    var totalDownCount: Int {
        var count = 0
        for row in rows {
            for status in row.grid {
                if status == .bigDown || status == .smallDown {
                    count += 1
                }
            }
        }
        return count
    }
}

// 本地离线持久化管理类
class StorageManager: ObservableObject {
    static let shared = StorageManager()
    
    @Published var records: [String: DailyRecord] = [:]
    private let recordsKey = "SavedTradingRecords_v3"
    
    init() {
        loadData()
    }
    
    func saveRecord(_ record: DailyRecord) {
        records[record.id] = record
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: recordsKey)
        }
    }
    
    func deleteRecord(id: String) {
        records.removeValue(forKey: id)
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: recordsKey)
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: recordsKey),
           let decoded = try? JSONDecoder().decode([String: DailyRecord].self, from: data) {
            self.records = decoded
        }
    }
}
