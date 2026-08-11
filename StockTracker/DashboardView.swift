import SwiftUI

struct DashboardView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var selectedDate = Date()
    
    var currentDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }
    
    var currentRecord: DailyRecord {
        storage.records[currentDateString] ?? DailyRecord(
            dateString: currentDateString,
            rows: (1...8).map { _ in DailyGridRow() }
        )
    }
    
    private func formatScore(_ score: Double) -> String {
        if score.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", score)
        } else {
            return String(format: "%.2f", score)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 1. 顶部日期 & 关联个股栏
                VStack(spacing: 6) {
                    HStack {
                        DatePicker("选择日期", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                        
                        Spacer()
                        
                        // 显示绑定个股
                        if !currentRecord.stockCode.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.caption)
                                Text("\(currentRecord.stockName)(\(currentRecord.stockCode))")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        } else {
                            Text("全局/大盘")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // 显示备注卡片
                    if !currentRecord.remark.isEmpty {
                        HStack {
                            Text("备注：\(currentRecord.remark)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                            Spacer()
                        }
                        .padding(8)
                        .background(Color(UIColor.tertiarySystemFill))
                        .cornerRadius(6)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGroupedBackground))
                
                // 2. 网格看板列表
                List {
                    Section(header: HStack {
                        Text("行号").frame(width: 35, alignment: .leading)
                        Text("5列涨跌网格").frame(maxWidth: .infinity)
                        Text("分值").frame(width: 50, alignment: .trailing)
                    }.font(.caption).foregroundColor(.gray)) {
                        ForEach(Array(currentRecord.rows.enumerated()), id: \.offset) { index, row in
                            HStack {
                                Text("\(index + 1)")
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .frame(width: 35, alignment: .leading)
                                
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
                                
                                Text(formatScore(row.score))
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.semibold)
                                    .frame(width: 50, alignment: .trailing)
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
            .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
            .withFloatingTHSButton()
        }
    }
}
