import SwiftUI

struct DashboardView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var selectedDate = Date()
    @State private var showingDetailSheet = false
    
    private let weekLabels = ["第一周", "第二周", "第三周", "第四周", "第五周", "第六周"]
    
    // 只保留年和月 (如 2026年 09月)
    var currentYearMonthString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "yyyy年 MM月"
        return formatter.string(from: selectedDate)
    }
    
    var currentDateKey: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: selectedDate)
    }
    
    // 仅显示当月的数据（默认 4 周）
    var currentRecord: DailyRecord {
        storage.records[currentDateKey] ?? DailyRecord(
            recordKey: currentDateKey,
            rows: (1...4).map { _ in DailyGridRow() }
        )
    }
    
    private func formatDateRange(start: Date, end: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MM-dd"
        return "\(f.string(from: start)) ━ \(f.string(from: end))"
    }
    
    private func formatScore(_ score: Double) -> String {
        return score.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", score) : String(format: "%.2f", score)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 1. 顶部年月选择 Header (只显示年和月)
                HStack {
                    DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                    
                    Spacer()
                    
                    Text(currentYearMonthString)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color(UIColor.systemGroupedBackground))
                
                // 2. 晴雨板列表（第一周 ~ 第四周）
                List {
                    Section(header: Text("晴雨板看板 (当月) - 点击修改备注").font(.caption)) {
                        ForEach(0..<currentRecord.rows.count, id: \.self) { index in
                            let row = currentRecord.rows[index]
                            let label = index < weekLabels.count ? weekLabels[index] : "第\(index+1)周"
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("【\(label)】  \(formatDateRange(start: row.startDate, end: row.endDate))")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Text("分值: \(formatScore(row.score))")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                                
                                // 格子美观间隔 (spacing: 6)
                                HStack(spacing: 6) {
                                    ForEach(0..<5, id: \.self) { col in
                                        let status = col < row.grid.count ? row.grid[col] : .smallUp
                                        Text(status.rawValue)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, minHeight: 30)
                                            .background(status.color)
                                            .cornerRadius(6)
                                    }
                                }
                                
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
                
                // 底部统计
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
                    
                    Button("查看与修改当月详情备注") {
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
                RecordDetailSheet(recordKey: currentDateKey)
            }
        }
    }
}
