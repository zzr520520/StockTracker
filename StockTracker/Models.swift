import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum GridStatus: String, Codable, CaseIterable {
    case bigUp = "大涨"
    case smallUp = "小涨"
    case smallDown = "小跌"
    case bigDown = "大跌"
    
    var color: Color {
        switch self {
        case .bigUp: return Color(red: 0.85, green: 0.1, blue: 0.1)
        case .smallUp: return Color(red: 1.0, green: 0.5, blue: 0.5)
        case .smallDown: return Color(red: 0.5, green: 0.85, blue: 0.5)
        case .bigDown: return Color(red: 0.1, green: 0.6, blue: 0.1)
        }
    }
}

// 单周数据，用 isSet 标识是否真正设置保存过
struct DailyGridRow: Identifiable, Codable {
    var id = UUID()
    var isSet: Bool = false      // 标识是否已设置数据
    var startDate: Date = Date()
    var endDate: Date = Date()
    var rowRemark: String = ""
    var grid: [GridStatus] = Array(repeating: .smallUp, count: 5)
    var score: Double = 0.0
}

struct DailyRecord: Identifiable, Codable {
    var id: String { recordKey }
    var recordKey: String // yyyy-MM
    var rows: [DailyGridRow]
    
    // 用 for 循环避免编译器超时
    var bigUpCount: Int {
        var count = 0
        for row in rows {
            if !row.isSet { continue }
            for s in row.grid {
                if s == .bigUp { count += 1 }
            }
        }
        return count
    }
    var smallUpCount: Int {
        var count = 0
        for row in rows {
            if !row.isSet { continue }
            for s in row.grid {
                if s == .smallUp { count += 1 }
            }
        }
        return count
    }
    var bigDownCount: Int {
        var count = 0
        for row in rows {
            if !row.isSet { continue }
            for s in row.grid {
                if s == .bigDown { count += 1 }
            }
        }
        return count
    }
    var smallDownCount: Int {
        var count = 0
        for row in rows {
            if !row.isSet { continue }
            for s in row.grid {
                if s == .smallDown { count += 1 }
            }
        }
        return count
    }
}

// 自定义仅"年+月"选择器控件
struct MonthPickerView: View {
    @Binding var selectedYear: Int
    @Binding var selectedMonth: Int
    @Environment(\.dismiss) var dismiss
    
    let years = Array(2020...2035)
    let months = Array(1...12)
    
    var body: some View {
        NavigationView {
            HStack {
                Picker("年份", selection: $selectedYear) {
                    ForEach(years, id: \.self) { y in
                        Text("\(String(y))年").tag(y)
                    }
                }
                .pickerStyle(.wheel)
                
                Picker("月份", selection: $selectedMonth) {
                    ForEach(months, id: \.self) { m in
                        Text("\(m)月").tag(m)
                    }
                }
                .pickerStyle(.wheel)
            }
            .navigationTitle("选择年月")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("确定") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
    }
}

class StorageManager: ObservableObject {
    static let shared = StorageManager()
    @Published var records: [String: DailyRecord] = [:]
    private let recordsKey = "SunnyRainStorage_v9"
    
    init() { loadData() }
    
    func saveSingleRow(recordKey: String, rowIndex: Int, rowData: DailyGridRow) {
        var current = records[recordKey] ?? DailyRecord(recordKey: recordKey, rows: (1...4).map { _ in DailyGridRow() })
        if rowIndex < current.rows.count {
            current.rows[rowIndex] = rowData
            current.rows[rowIndex].isSet = true // 标记为已设置
            records[recordKey] = current
            syncToDisk()
        }
    }
    
    func resetSingleRow(recordKey: String, rowIndex: Int) {
        if var current = records[recordKey], rowIndex < current.rows.count {
            current.rows[rowIndex] = DailyGridRow() // 恢复为空未设置状态
            records[recordKey] = current
            syncToDisk()
        }
    }
    
    // 仅更新备注（晴雨板点击修改备注用）
    func updateRemark(recordKey: String, rowIndex: Int, remark: String) {
        var current = records[recordKey] ?? DailyRecord(recordKey: recordKey, rows: (1...4).map { _ in DailyGridRow() })
        if rowIndex < current.rows.count {
            current.rows[rowIndex].rowRemark = remark
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
    
    // 生成 JSON 备份数据（用于 fileExporter）
    func generateBackupData() -> Data? {
        return try? JSONEncoder().encode(records)
    }
    
    // 从 JSON 数据恢复
    func importFromData(_ data: Data) -> Bool {
        if let decoded = try? JSONDecoder().decode([String: DailyRecord].self, from: data) {
            self.records = decoded
            syncToDisk()
            return true
        }
        return false
    }
    
    // 从文件 URL 恢复
    func importFromURL(_ url: URL) -> Bool {
        guard url.startAccessingSecurityScopedResource() else {
            return decodeAndSave(from: url)
        }
        defer { url.stopAccessingSecurityScopedResource() }
        return decodeAndSave(from: url)
    }
    
    private func decodeAndSave(from url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url) else { return false }
        return importFromData(data)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// 用于 sheet 绑定的字符串包装
struct IdentifiableString: Identifiable {
    var id: String { value }
    let value: String
}
