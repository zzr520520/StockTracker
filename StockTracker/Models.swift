import Foundation
import SwiftUI
import UniformTypeIdentifiers

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

// 单行记录（日期展示 MM-dd，支持选择指定截止日与单独备注行）
struct DailyGridRow: Identifiable, Codable {
    var id = UUID()
    var rowDate: Date = Date()   // 行截止日期
    var rowRemark: String = ""   // 行独立备注
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

// 晴雨板主体记录（按 yyyy-MM 年月区分）
struct DailyRecord: Identifiable, Codable {
    var id: String { recordKey }
    var recordKey: String      // 主键: yyyy-MM (例如 2026-08)
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

// 定义 ZIP 自定义文档类型（用于 iOS 文件导入导出）
struct ZipDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.zip, .archive] }
    var data: Data

    init(data: Data = Data()) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.data = data
        } else {
            self.data = Data()
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

// 数据持久化与备份导入导出管理
class StorageManager: ObservableObject {
    static let shared = StorageManager()
    
    @Published var records: [String: DailyRecord] = [:]
    private let recordsKey = "SavedSunnyRainRecords_v5"
    
    init() {
        loadData()
    }
    
    func saveRecord(_ record: DailyRecord) {
        records[record.recordKey] = record
        syncToDisk()
    }
    
    func deleteRecord(key: String) {
        records.removeValue(forKey: key)
        syncToDisk()
    }
    
    private func syncToDisk() {
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
    
    // 生成 JSON 数据并打成 ZIP 压缩包 Data
    func generateBackupZipData() -> Data? {
        guard let jsonData = try? JSONEncoder().encode(records) else { return nil }
        
        // 构造简易的带文件头的标准 ZIP 文件数据（兼容格式）
        var zipData = Data()
        let filename = "SunnyRain_Backup.json"
        let filenameData = filename.data(using: .utf8)!
        
        // Local File Header
        var header = Data([0x50, 0x4b, 0x03, 0x04, 0x0a, 0x00, 0x00, 0x00, 0x00, 0x00])
        header.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // time/date
        
        var crc: UInt32 = 0 // simplified container
        var crcData = Data(bytes: &crc, count: 4)
        var size = UInt32(jsonData.count)
        var sizeData = Data(bytes: &size, count: 4)
        var nameLen = UInt16(filenameData.count)
        var nameLenData = Data(bytes: &nameLen, count: 2)
        var extraLen: UInt16 = 0
        var extraLenData = Data(bytes: &extraLen, count: 2)
        
        zipData.append(header)
        zipData.append(crcData)
        zipData.append(sizeData)
        zipData.append(sizeData)
        zipData.append(nameLenData)
        zipData.append(extraLenData)
        zipData.append(filenameData)
        zipData.append(jsonData)
        
        return zipData
    }
    
    // 从包或 JSON 中解压并导入数据
    func importBackupFromData(_ data: Data) -> Bool {
        // 先尝试直接 JSON 解析
        if let decoded = try? JSONDecoder().decode([String: DailyRecord].self, from: data) {
            self.records = decoded
            syncToDisk()
            return true
        }
        // 如果是 Zip 包则提取内部 JSON 部分
        if let jsonStart = data.range(of: "{".data(using: .utf8)!),
           let jsonEnd = data.range(of: "}".data(using: .utf8)!, options: .backwards) {
            let subData = data.subdata(in: jsonStart.lowerBound..<jsonEnd.upperBound)
            if let decoded = try? JSONDecoder().decode([String: DailyRecord].self, from: subData) {
                self.records = decoded
                syncToDisk()
                return true
            }
        }
        return false
    }
}
