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
            recordKey: currentDateString,
            rows: (1...6).map { _ in DailyGridRow() }
        )
    }
    
    private func formatScore(_ score: Double) -> String {
        if score.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", score)
        } else {
            return String(format: "%.2f", score)
        }
    }
    
    private func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部日期切换 Header
                HStack {
                    DatePicker("日期", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                    
                    Spacer()
                    
                    Text(currentDateString)
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color(UIColor.systemGroupedBackground))
                
                // 网格展示
                List {
                    Section(header: HStack {
                        Text("日期/备注").frame(width: 80, alignment: .leading)
                        HStack {
                            Text("周一").frame(maxWidth: .infinity)
                            Text("周二").frame(maxWidth: .infinity)
                            Text("周三").frame(maxWidth: .infinity)
                            Text("周四").frame(maxWidth: .infinity)
                            Text("周五").frame(maxWidth: .infinity)
                        }
                        Text("分值").frame(width: 40, alignment: .trailing)
                    }.font(.caption).foregroundColor(.gray)) {
                        ForEach(currentRecord.rows) { row in
                            HStack {
                                // 左侧：日期与备注
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(formatDateShort(row.rowDate))
                                        .font(.system(size: 11, weight: .bold))
                                    if !row.rowRemark.isEmpty {
                                        Text(row.rowRemark)
                                            .font(.system(size: 9))
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                }
                                .frame(width: 80, alignment: .leading)
                                
                                // 中间：5 交易日网格
                                HStack(spacing: 3) {
                                    ForEach(0..<5, id: \.self) { colIndex in
                                        let status = colIndex < row.grid.count ? row.grid[colIndex] : .smallUp
                                        Text(status.rawValue)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, minHeight: 32)
                                            .background(status.color)
                                            .cornerRadius(5)
                                    }
                                }
                                
                                // 右侧：分值
                                Text(formatScore(row.score))
                                    .font(.system(.caption, design: .monospaced))
                                    .fontWeight(.semibold)
                                    .frame(width: 40, alignment: .trailing)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                
                // 底部 4 项指标统计（大涨/小涨/大跌/小跌合计）
                VStack(spacing: 8) {
                    HStack {
                        HStack(spacing: 4) {
                            Text("大涨合计:")
                            Text("\(currentRecord.bigUpCount)")
                                .fontWeight(.bold)
                                .foregroundColor(GridStatus.bigUp.color)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Text("小涨合计:")
                            Text("\(currentRecord.smallUpCount)")
                                .fontWeight(.bold)
                                .foregroundColor(GridStatus.smallUp.color)
                        }
                    }
                    Divider()
                    HStack {
                        HStack(spacing: 4) {
                            Text("大跌合计:")
                            Text("\(currentRecord.bigDownCount)")
                                .fontWeight(.bold)
                                .foregroundColor(GridStatus.bigDown.color)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Text("小跌合计:")
                            Text("\(currentRecord.smallDownCount)")
                                .fontWeight(.bold)
                                .foregroundColor(GridStatus.smallDown.color)
                        }
                    }
                }
                .font(.subheadline)
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle("晴雨板")
            .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
            .withFloatingTHSButton()
        }
    }
}
