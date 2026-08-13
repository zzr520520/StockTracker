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

// 包含左侧日期和备注的单行记录
struct DailyGridRow: Identifiable, Codable {
    var id = UUID()
    var rowDate: Date = Date()   // 左侧行日期
    var rowRemark: String = ""   // 左侧行备注
    var grid: [GridStatus]      // 5 列网格（周一至周五）
    var score: Double           // 右侧分值
    
    init(rowDate: Date = Date(), rowRemark: String = "", grid: [GridStatus] = Array(repeating: .smallUp, count: 5), score: Double = 0.0) {
        self.id = UUID()
        self.rowDate = rowDate
        self.rowRemark = rowRemark
        self.grid = grid
        self.score = score
    }
}

// 晴雨板整体记录
struct DailyRecord: Identifiable, Codable {
    var id: String { recordKey }
    var recordKey: String      // 记录唯一标识
    var rows: [DailyGridRow]
    
    // 统计大涨、小涨、大跌、小跌合计数量（用 for 循环避免编译器超时）
    var bigUpCount: Int {
        var count = 0
        for row in rows {
            for s in row.grid {
                if s == .bigUp { count += 1 }
            }
        }
        return count
    }
    var smallUpCount: Int {
        var count = 0
        for row in rows {
            for s in row.grid {
                if s == .smallUp { count += 1 }
            }
        }
        return count
    }
    var bigDownCount: Int {
        var count = 0
        for row in rows {
            for s in row.grid {
                if s == .bigDown { count += 1 }
            }
        }
        return count
    }
    var smallDownCount: Int {
        var count = 0
        for row in rows {
            for s in row.grid {
                if s == .smallDown { count += 1 }
            }
        }
        return count
    }
}

// 数据持久化
class StorageManager: ObservableObject {
    static let shared = StorageManager()
    
    @Published var records: [String: DailyRecord] = [:]
    private let recordsKey = "SavedSunnyRainRecords_v4"
    
    init() {
        loadData()
    }
    
    func saveRecord(_ record: DailyRecord) {
        records[record.recordKey] = record
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: recordsKey)
        }
    }
    
    func deleteRecord(key: String) {
        records.removeValue(forKey: key)
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
