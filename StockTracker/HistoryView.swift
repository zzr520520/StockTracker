import SwiftUI

struct HistoryView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var searchText = ""
    
    // 支持直接根据"日期"或"备注"关键词检索
    var filteredRecords: [DailyRecord] {
        let all = Array(storage.records.values).sorted { $0.recordKey > $1.recordKey }
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return all
        }
        var result: [DailyRecord] = []
        for record in all {
            let matchDate = record.recordKey.contains(trimmed)
            var matchRemark = false
            for row in record.rows {
                if row.rowRemark.contains(trimmed) {
                    matchRemark = true
                    break
                }
            }
            if matchDate || matchRemark {
                result.append(record)
            }
        }
        return result
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(filteredRecords) { record in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(record.recordKey)
                                    .font(.headline)
                                Spacer()
                                Text("大涨:\(record.bigUpCount) 小涨:\(record.smallUpCount) 大跌:\(record.bigDownCount) 小跌:\(record.smallDownCount)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            
                            // 显示匹配的备注信息
                            let remarks = record.rows.map { $0.rowRemark }.filter { !$0.isEmpty }
                            if !remarks.isEmpty {
                                Text("备注包含: \(remarks.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                            
                            // 缩略网格预览
                            VStack(spacing: 2) {
                                ForEach(record.rows.prefix(3)) { row in
                                    HStack(spacing: 3) {
                                        ForEach(0..<5, id: \.self) { col in
                                            let st = col < row.grid.count ? row.grid[col] : .smallUp
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(st.color)
                                                .frame(height: 6)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let item = filteredRecords[index]
                            storage.deleteRecord(key: item.recordKey)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("历史记录")
            .searchable(text: $searchText, prompt: "搜索日期或备注内容...")
            .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
            .withFloatingTHSButton()
        }
    }
}
