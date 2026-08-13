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

// 单行数据结构
struct DailyGridRow: Identifiable, Codable {
    var id = UUID()
    var startDate: Date = Date() // 开始日期
    var endDate: Date = Date()   // 结束日期 (自动为 start + 4 天)
    var rowRemark: String = ""   // 独立备注
    var grid: [GridStatus]      // 5列涨跌格子
    var score: Double           // 分值
    
    init(startDate: Date = Date(), endDate: Date? = nil, rowRemark: String = "", grid: [GridStatus] = Array(repeating: .smallUp, count: 5), score: Double = 0.0) {
        self.id = UUID()
        self.startDate = startDate
        self.endDate = endDate ?? Calendar.current.date(byAdding: .day, value: 4, to: startDate) ?? startDate
        self.rowRemark = rowRemark
        self.grid = grid
        self.score = score
    }
}

// 晴雨板主数据模型 (按 yyyy-MM 归档)
struct DailyRecord: Identifiable, Codable {
    var id: String { recordKey }
    var recordKey: String // 格式: yyyy-MM
    var rows: [DailyGridRow]
    
    // 用 for 循环避免编译器超时
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

// 系统原生分享包
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// 用于 sheet 绑定的字符串包装
struct IdentifiableString: Identifiable {
    var id: String { value }
    let value: String
}

// 数据持久化管理类
class StorageManager: ObservableObject {
    static let shared = StorageManager()
    
    @Published var records: [String: DailyRecord] = [:]
    private let recordsKey = "SunnyRainStorage_v8"
    
    init() {
        loadData()
    }
    
    func saveRecord(_ record: DailyRecord) {
        records[record.recordKey] = record
        syncToDisk()
    }
    
    func saveSingleRow(recordKey: String, rowIndex: Int, rowData: DailyGridRow) {
        var current = records[recordKey] ?? DailyRecord(recordKey: recordKey, rows: (1...4).map { _ in DailyGridRow() })
        if rowIndex < current.rows.count {
            current.rows[rowIndex] = rowData
            records[recordKey] = current
            syncToDisk()
        }
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
    
    // 生成 Zip 备份文件用于分享
    func generateZipFileURL() -> URL? {
        guard let jsonData = try? JSONEncoder().encode(records) else { return nil }
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("SunnyRain_Backup_\(Int(Date().timeIntervalSince1970)).zip")
        
        var zipData = Data()
        let filename = "backup.json"
        let filenameData = filename.data(using: .utf8)!
        
        var header = Data([0x50, 0x4b, 0x03, 0x04, 0x14, 0x00, 0x00, 0x00, 0x00, 0x00])
        header.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        
        var crc: UInt32 = 0
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
        
        do {
            try zipData.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }
    
    func importFromURL(_ url: URL) -> Bool {
        guard url.startAccessingSecurityScopedResource() else {
            return decodeAndSave(from: url)
        }
        defer { url.stopAccessingSecurityScopedResource() }
        return decodeAndSave(from: url)
    }
    
    private func decodeAndSave(from url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url) else { return false }
        if let decoded = try? JSONDecoder().decode([String: DailyRecord].self, from: data) {
            self.records = decoded
            syncToDisk()
            return true
        }
        if let start = data.range(of: "{".data(using: .utf8)!),
           let end = data.range(of: "}".data(using: .utf8)!, options: .backwards) {
            let jsonSlice = data.subdata(in: start.lowerBound..<end.upperBound)
            if let decoded = try? JSONDecoder().decode([String: DailyRecord].self, from: jsonSlice) {
                self.records = decoded
                syncToDisk()
                return true
            }
        }
        return false
    }
}
