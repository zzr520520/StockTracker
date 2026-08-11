import SwiftUI

struct DashboardView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var selectedDate = Date()
    @State private var selectedStockCode: String = "" // 当前选中的股票代码，为空代表通用/大盘
    
    var currentDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }
    
    // 根据 日期 + 股票代码 获取专属记录
    var currentRecord: DailyRecord {
        let key = "\(currentDateString)_\(selectedStockCode.isEmpty ? "GLOBAL" : selectedStockCode)"
        return storage.records[key] ?? DailyRecord(
            dateString: currentDateString,
            stockCode: selectedStockCode,
            stockName: storage.favoriteStocks.first(where: { $0.code == selectedStockCode })?.name ?? "",
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
                // 1. 顶部日期与股票切换栏
                VStack(spacing: 10) {
                    HStack {
                        DatePicker("日期", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                        
                        Spacer()
                        
                        // 切换要查看的股票看板
                        Picker("选择股票", selection: $selectedStockCode) {
                            Text("通用/大盘").tag("")
                            ForEach(storage.favoriteStocks) { stock in
                                Text("\(stock.name) (\(stock.code))").tag(stock.code)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // 备注卡片展示
                    if !currentRecord.remark.isEmpty {
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundColor(.gray)
                            Text("备注：\(currentRecord.remark)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(8)
                        .background(Color(UIColor.tertiarySystemFill))
                        .cornerRadius(6)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGroupedBackground))
                
                // 2. 网格看板数据
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
                
                // 3. 统计底栏
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
