import SwiftUI

struct RecordDetailSheet: View {
    let record: DailyRecord
    @Environment(\.dismiss) var dismiss
    
    private func formatDateRange(start: Date, end: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "M月d日"
        return "\(f.string(from: start)) - \(f.string(from: end))"
    }
    
    private func formatScore(_ score: Double) -> String {
        return score.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", score) : String(format: "%.2f", score)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 涨跌概览卡片
                    VStack(spacing: 8) {
                        Text("涨跌汇总统计")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        HStack {
                            VStack {
                                Text("大涨").font(.caption).foregroundColor(.gray)
                                Text("\(record.bigUpCount)").font(.title3).bold().foregroundColor(GridStatus.bigUp.color)
                            }.frame(maxWidth: .infinity)
                            
                            VStack {
                                Text("小涨").font(.caption).foregroundColor(.gray)
                                Text("\(record.smallUpCount)").font(.title3).bold().foregroundColor(GridStatus.smallUp.color)
                            }.frame(maxWidth: .infinity)
                            
                            VStack {
                                Text("大跌").font(.caption).foregroundColor(.gray)
                                Text("\(record.bigDownCount)").font(.title3).bold().foregroundColor(GridStatus.bigDown.color)
                            }.frame(maxWidth: .infinity)
                            
                            VStack {
                                Text("小跌").font(.caption).foregroundColor(.gray)
                                Text("\(record.smallDownCount)").font(.title3).bold().foregroundColor(GridStatus.smallDown.color)
                            }.frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    
                    // 独行布局展示
                    VStack(alignment: .leading, spacing: 14) {
                        Text("明细情况").font(.headline).padding(.horizontal)
                        
                        ForEach(Array(record.rows.enumerated()), id: \.offset) { index, row in
                            VStack(alignment: .leading, spacing: 8) {
                                // 1. 日期区间与分值独立第一行
                                HStack {
                                    Text("日期：\(formatDateRange(start: row.startDate, end: row.endDate))")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Text("分值：\(formatScore(row.score))")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                
                                // 2. 涨跌格子独立第二行
                                HStack(spacing: 4) {
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
                                
                                // 3. 备注独立第三行
                                if !row.rowRemark.isEmpty {
                                    HStack(alignment: .top) {
                                        Image(systemName: "square.and.pencil")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                        Text("备注：\(row.rowRemark)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.orange.opacity(0.08))
                                    .cornerRadius(6)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("晴雨板明细 (\(record.recordKey))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}
