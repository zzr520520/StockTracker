import Foundation

enum GridStatus: String, Codable, CaseIterable {
    case up = "涨"
    case down = "跌"
}

struct DailyGridRow: Identifiable, Codable {
    var id = UUID()
    var grid: [GridStatus]
    var score: Double
    
    init(grid: [GridStatus] = Array(repeating: .up, count: 5), score: Double = 0.0) {
        self.grid = grid
        self.score = score
    }
}

// 每日记录模型（复合主键：日期_股票代码）
struct DailyRecord: Identifiable, Codable {
    // 复合唯一 ID：例如 "2026-08-11_00700" 或 "2026-08-11_GLOBAL"
    var id: String { 
        let code = stockCode.isEmpty ? "GLOBAL" : stockCode
        return "\(dateString)_\(code)" 
    }
    
    var dateString: String
    var stockCode: String = ""  // 股票代码
    var stockName: String = ""  // 股票名称
    var remark: String = ""     // 备注信息
    var rows: [DailyGridRow]
    
    var totalUpCount: Int {
        rows.flatMap { $0.grid }.filter { $0 == .up }.count
    }
    
    var totalDownCount: Int {
        rows.flatMap { $0.grid }.filter { $0 == .down }.count
    }
}

// 自选股票模型
struct StockItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var code: String
    var name: String
    var isPinned: Bool = false
}

// 数据持久化管理类
class StorageManager: ObservableObject {
    static let shared = StorageManager()
    
    @Published var records: [String: DailyRecord] = [:]
    @Published var favoriteStocks: [StockItem] = []
    
    private let recordsKey = "SavedDailyRecords_v2"
    private let stocksKey = "SavedFavoriteStocks_v2"
    
    init() {
        loadData()
        if favoriteStocks.isEmpty {
            favoriteStocks = [
                StockItem(code: "00700", name: "腾讯控股", isPinned: true),
                StockItem(code: "600519", name: "贵州茅台", isPinned: false),
                StockItem(code: "000001", name: "平安银行", isPinned: false)
            ]
            saveStocks()
        }
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
    
    func saveStocks() {
        if let encoded = try? JSONEncoder().encode(favoriteStocks) {
            UserDefaults.standard.set(encoded, forKey: stocksKey)
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: recordsKey),
           let decoded = try? JSONDecoder().decode([String: DailyRecord].self, from: data) {
            self.records = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: stocksKey),
           let decoded = try? JSONDecoder().decode([StockItem].self, from: data) {
            self.favoriteStocks = decoded
        }
    }
}
