import Foundation

// 涨跌网格格子状态
enum GridStatus: String, Codable, CaseIterable {
    case up = "涨"
    case down = "跌"
}

// 每日单行记录 (5列网格 + 分值)
struct DailyGridRow: Identifiable, Codable {
    var id = UUID()
    var grid: [GridStatus] // 固定 5 个
    var score: Int
    
    init(grid: [GridStatus] = Array(repeating: .up, count: 5), score: Int = 0) {
        self.grid = grid
        self.score = score
    }
}

// 每日完整的记录绑定
struct DailyRecord: Identifiable, Codable {
    var id: String { dateString } // 用 "yyyy-MM-dd" 作为主键
    var dateString: String
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

// 数据持久化管理类 (本地 JSON 离线存储)
class StorageManager: ObservableObject {
    static let shared = StorageManager()
    
    @Published var records: [String: DailyRecord] = [:]
    @Published var favoriteStocks: [StockItem] = []
    
    private let recordsKey = "SavedDailyRecords_v1"
    private let stocksKey = "SavedFavoriteStocks_v1"
    
    init() {
        loadData()
        if favoriteStocks.isEmpty {
            // 预设测试数据
            favoriteStocks = [
                StockItem(code: "600519", name: "贵州茅台", isPinned: true),
                StockItem(code: "000001", name: "平安银行", isPinned: false)
            ]
            saveStocks()
        }
    }
    
    // 记录存取
    func saveRecord(_ record: DailyRecord) {
        records[record.dateString] = record
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: recordsKey)
        }
    }
    
    func deleteRecord(dateString: String) {
        records.removeValue(forKey: dateString)
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: recordsKey)
        }
    }
    
    // 股票自选存取
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
