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

// 单行记录（涨幅格子独立一行，日期区间独立一行，备注独立一行）
struct DailyGridRow: Identifiable, Codable {
    var id = UUID()
    var startDate: Date = Date() // 开始日期 (如 8月3日)
    var endDate: Date = Date()   // 截止日期 (如 8月6日)
    var rowRemark: String = ""   // 独立备注
    var grid: [GridStatus]      // 5列涨跌格子 (独立一行)
    var score: Double           // 分值
    
    init(startDate: Date = Date(), endDate: Date = Date(), rowRemark: String = "", grid: [GridStatus] = Array(repeating: .smallUp, count: 5), score: Double = 0.0) {
        self.id = UUID()
        self.startDate = startDate
        self.endDate = endDate
        self.rowRemark = rowRemark
        self.grid = grid
        self.score = score
    }
}

// 主体晴雨板记录 (按年月 yyyy-MM 归档)
struct DailyRecord: Identifiable, Codable {
    var id: String { recordKey }
    var recordKey: String
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

// 原生系统分享调起器 (UIActivityViewController)
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// 数据管理与备份逻辑
class StorageManager: ObservableObject {
    static let shared = StorageManager()
    
    @Published var records: [String: DailyRecord] = [:]
    private let recordsKey = "SunnyRainStorage_v6"
    
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
    
    // 生成 Zip 临时文件用于系统分享
    func generateZipFileURL() -> URL? {
        guard let jsonData = try? JSONEncoder().encode(records) else { return nil }
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("SunnyRain_Backup_\(Int(Date().timeIntervalSince1970)).zip")
        
        // 构建带有 Zip 文件头的 Data
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
    
    // 读取与解包 Zip 导入备份
    func importFromURL(_ url: URL) -> Bool {
        guard url.startAccessingSecurityScopedResource() else {
            // 如果无法获得安全权限，尝试直接读取
            return decodeAndSave(from: url)
        }
        defer { url.stopAccessingSecurityScopedResource() }
        return decodeAndSave(from: url)
    }
    
    private func decodeAndSave(from url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url) else { return false }
        
        // 尝试直接 JSON 恢复
        if let decoded = try? JSONDecoder().decode([String: DailyRecord].self, from: data) {
            self.records = decoded
            syncToDisk()
            return true
        }
        
        // 如果是 Zip 提取包含的 JSON 内容
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
