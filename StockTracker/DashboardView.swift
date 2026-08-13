import SwiftUI

struct DashboardView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var year: Int = Calendar.current.component(.year, from: Date())
    @State private var month: Int = Calendar.current.component(.month, from: Date())
    @State private var showMonthPicker = false
    @State private var showDetailSheet = false
    
    private let weekLabels = ["第一周", "第二周", "第三周", "第四周"]
    
    var currentDateKey: String {
        String(format: "%04d-%02d", year, month)
    }
    
    var currentRecord: DailyRecord? {
        storage.records[currentDateKey]
    }
    
    private func formatDateRange(start: Date, end: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MM-dd"
        return "\(f.string(from: start)) ━ \(f.string(from: end))"
    }
    
    private func formatScore(_ score: Double) -> String {
        score.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", score) : String(format: "%.2f", score)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 1. 顶部年月切换（干净单一，只显示年和月，绝不带"日"）
                HStack {
                    Button(action: { showMonthPicker = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                            Text("\(String(year))年 \(month)月")
                                .font(.headline)
                                .fontWeight(.bold)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(UIColor.systemGroupedBackground))
                
                // 2. 晴雨板内容区（未设置数据的周显示空白卡片，设置过的才展示）
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(0..<4, id: \.self) { index in
                            let label = weekLabels[index]
                            let rowData: DailyGridRow? = {
                                guard let rec = currentRecord, index < rec.rows.count else { return nil }
                                return rec.rows[index]
                            }()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("【\(label)】")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                    
                                    if let row = rowData, row.isSet {
                                        Text(formatDateRange(start: row.startDate, end: row.endDate))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text("分值: \(formatScore(row.score))")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    } else {
                                        Spacer()
                                        Text("未设置数据")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                if let row = rowData, row.isSet {
                                    // 已设置数据的网格
                                    HStack(spacing: 6) {
                                        ForEach(0..<5, id: \.self) { col in
                                            let status = col < row.grid.count ? row.grid[col] : .smallUp
                                            Text(status.rawValue)
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity, minHeight: 32)
                                                .background(status.color)
                                                .cornerRadius(6)
                                        }
                                    }
                                    
                                    if !row.rowRemark.isEmpty {
                                        Text("备注: \(row.rowRemark)")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                } else {
                                    // 未设置数据的优雅空白占位格
                                    HStack(spacing: 6) {
                                        ForEach(0..<5, id: \.self) { _ in
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color(UIColor.tertiarySystemFill))
                                                .frame(maxWidth: .infinity, minHeight: 32)
                                                .overlay(Text("-").foregroundColor(.gray))
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding()
                }
                .background(Color(UIColor.systemGroupedBackground))
                
                // 底部统计栏
                VStack(spacing: 6) {
                    HStack {
                        Text("大涨: \(currentRecord?.bigUpCount ?? 0)").foregroundColor(GridStatus.bigUp.color)
                        Spacer()
                        Text("小涨: \(currentRecord?.smallUpCount ?? 0)").foregroundColor(GridStatus.smallUp.color)
                        Spacer()
                        Text("大跌: \(currentRecord?.bigDownCount ?? 0)").foregroundColor(GridStatus.bigDown.color)
                        Spacer()
                        Text("小跌: \(currentRecord?.smallDownCount ?? 0)").foregroundColor(GridStatus.smallDown.color)
                    }
                    .font(.caption)
                    .fontWeight(.bold)
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: -1)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle("晴雨板")
            .sheet(isPresented: $showMonthPicker) {
                MonthPickerView(selectedYear: $year, selectedMonth: $month)
            }
        }
    }
}
