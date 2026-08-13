import SwiftUI

struct HistoryView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var filterDate = Date()
    @State private var isFilteringByDate = false
    
    var sortedRecords: [DailyRecord] {
        let all = Array(storage.records.values).sorted { $0.dateString > $1.dateString }
        if isFilteringByDate {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_Hans_CN")
            formatter.dateFormat = "yyyy-MM-dd"
            let dateStr = formatter.string(from: filterDate)
            return all.filter { $0.dateString == dateStr }
        }
        return all
    }
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Toggle("按日期筛选", isOn: $isFilteringByDate)
                    if isFilteringByDate {
                        DatePicker("", selection: $filterDate, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                            .labelsHidden()
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                
                List {
                    ForEach(sortedRecords) { record in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(record.dateString)
                                    .font(.headline)
                                
                                if !record.tagNote.isEmpty {
                                    Text("[\(record.tagNote)]")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                                
                                Spacer()
                                Text("涨: \(record.totalUpCount)  跌: \(record.totalDownCount)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            // 缩略预览
                            VStack(spacing: 3) {
                                ForEach(record.rows.prefix(3)) { row in
                                    HStack(spacing: 4) {
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
                            let item = sortedRecords[index]
                            storage.deleteRecord(id: item.id)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("历史记录")
            .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
            .withFloatingTHSButton()
        }
    }
}
