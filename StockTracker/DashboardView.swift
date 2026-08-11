import SwiftUI

struct DashboardView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var selectedDate = Date()
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
    
    var currentDateString: String {
        dateFormatter.string(from: selectedDate)
    }
    
    var currentRecord: DailyRecord {
        storage.records[currentDateString] ?? DailyRecord(
            dateString: currentDateString,
            rows: (1...8).map { _ in DailyGridRow() }
        )
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 1. 顶部日期选择器
                HStack {
                    DatePicker("选择日期", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    Spacer()
                    Text(currentDateString)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.systemGroupedBackground))
                
                // 2. 核心网格看板
                List {
                    Section(header: HStack {
                        Text("行号").frame(width: 35, alignment: .leading)
                        Text("5列涨跌网格").frame(maxWidth: .infinity)
                        Text("分值").frame(width: 45, alignment: .trailing)
                    }.font(.caption).foregroundColor(.gray)) {
                        ForEach(Array(currentRecord.rows.enumerated()), id: \.offset) { index, row in
                            HStack {
                                // 行号
                                Text("\(index + 1)")
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .frame(width: 35, alignment: .leading)
                                
                                // 5列网格
                                HStack(spacing: 6) {
                                    ForEach(0..<5, id: \.self) { colIndex in
                                        let status = colIndex < row.grid.count ? row.grid[colIndex] : .up
                                        Text(status.rawValue)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, minHeight: 32)
                                            .background(status == .up ? Color.red : Color.green)
                                            .cornerRadius(6)
                                    }
                                }
                                
                                // 分值
                                Text("\(row.score)")
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.semibold)
                                    .frame(width: 45, alignment: .trailing)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                
                // 3. 底部统计栏
                HStack {
                    HStack(spacing: 4) {
                        Text("总上涨:")
                        Text("\(currentRecord.totalUpCount)")
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Text("总下跌:")
                        Text("\(currentRecord.totalDownCount)")
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle("行情看板")
            .withFloatingTHSButton()
        }
    }
}
