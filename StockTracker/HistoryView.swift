import SwiftUI

struct HistoryView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var filterDate = Date()
    @State private var isFilteringByDate = false
    
    var sortedRecords: [DailyRecord] {
        let all = Array(storage.records.values).sorted { $0.dateString > $1.dateString }
        if isFilteringByDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateStr = formatter.string(from: filterDate)
            return all.filter { $0.dateString == dateStr }
        }
        return all
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 日历筛选框
                HStack {
                    Toggle("按日期筛选", isOn: $isFilteringByDate)
                    if isFilteringByDate {
                        DatePicker("", selection: $filterDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                
                List {
                    ForEach(sortedRecords) { record in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(record.dateString)
                                    .font(.headline)
                                Spacer()
                                Text("涨: \(record.totalUpCount)  跌: \(record.totalDownCount)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            // 缩略网格预览 (展示前 3 行)
                            VStack(spacing: 3) {
                                ForEach(record.rows.prefix(3)) { row in
                                    HStack(spacing: 4) {
                                        ForEach(0..<5, id: \.self) { col in
                                            let st = col < row.grid.count ? row.grid[col] : .up
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(st == .up ? Color.red : Color.green)
                                                .frame(height: 8)
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
                            storage.deleteRecord(dateString: item.dateString)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("历史记录")
            .withFloatingTHSButton()
        }
    }
}
