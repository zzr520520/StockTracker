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
    
    // 固定 8 行（前4行当月，后4行下个月，共2个月）
    var currentRecord: DailyRecord {
        storage.records[currentDateKey] ?? DailyRecord(
            recordKey: currentDateKey,
            rows: (1...8).map { _ in DailyGridRow() }
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
                
                // 8 行晴雨板展示（前4行为第1个月，后4行为第2个月）
                List {
                    Section(header: Text("晴雨板 (共 8 行 / 2 个月，点击可修改备注)").font(.caption)) {
                        ForEach(0..<currentRecord.rows.count, id: \.self) { index in
                            let row = currentRecord.rows[index]
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("【第 \(index + 1) 行】\(formatDateRange(start: row.startDate, end: row.endDate))")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(index < 4 ? .blue : .purple)
                                    Spacer()
                                    Text("分值: \(formatScore(row.score))")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                                
                                // 涨跌格子
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
                
                // 底部 4 指标统计
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
                    
                    Button("查看与修改晴雨板备注") {
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
