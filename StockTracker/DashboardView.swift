import SwiftUI

struct DashboardView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var selectedDate = Date()
    @State private var showingDetailSheet = false
    
    var currentDateKey: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: selectedDate)
    }
    
    var currentRecord: DailyRecord {
        storage.records[currentDateKey] ?? DailyRecord(
            recordKey: currentDateKey,
            rows: (1...6).map { _ in DailyGridRow() }
        )
    }
    
    private func formatDateRange(start: Date, end: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "M.d"
        return "\(f.string(from: start))-\(f.string(from: end))"
    }
    
    private func formatScore(_ score: Double) -> String {
        return score.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", score) : String(format: "%.2f", score)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部年月选择 Header
                HStack {
                    DatePicker("选择年月", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                    
                    Spacer()
                    
                    Text(currentDateKey)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color(UIColor.systemGroupedBackground))
                
                // 看板主视图
                List {
                    Section(header: Text("点击卡片可查看完整备注与详情").font(.caption)) {
                        ForEach(currentRecord.rows) { row in
                            VStack(alignment: .leading, spacing: 6) {
                                // 1. 日期区间与分值第一行
                                HStack {
                                    Text(formatDateRange(start: row.startDate, end: row.endDate))
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Text("分值: \(formatScore(row.score))")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                                
                                // 2. 涨幅格子独立第二行
                                HStack(spacing: 4) {
                                    ForEach(0..<5, id: \.self) { col in
                                        let status = col < row.grid.count ? row.grid[col] : .smallUp
                                        Text(status.rawValue)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, minHeight: 28)
                                            .background(status.color)
                                            .cornerRadius(5)
                                    }
                                }
                                
                                // 3. 备注独立第三行
                                if !row.rowRemark.isEmpty {
                                    Text("备注: \(row.rowRemark)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.orange)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showingDetailSheet = true
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                
                // 底部 4 统计项
                VStack(spacing: 6) {
                    HStack {
                        Text("大涨: \(currentRecord.bigUpCount)").foregroundColor(GridStatus.bigUp.color)
                        Spacer()
                        Text("小涨: \(currentRecord.smallUpCount)").foregroundColor(GridStatus.smallUp.color)
                        Spacer()
                        Text("大跌: \(currentRecord.bigDownCount)").foregroundColor(GridStatus.bigDown.color)
                        Spacer()
                        Text("小跌: \(currentRecord.smallDownCount)").foregroundColor(GridStatus.smallDown.color)
                    }
                    .font(.caption)
                    .fontWeight(.bold)
                    
                    Button("查看详细明细") {
                        showingDetailSheet = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 2)
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle("晴雨板")
            .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
            .sheet(isPresented: $showingDetailSheet) {
                RecordDetailSheet(record: currentRecord)
            }
        }
    }
}
