import SwiftUI

struct RecordDetailSheet: View {
    let record: DailyRecord
    @Environment(\.dismiss) var dismiss
    
    private func formatDateMMdd(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter.string(from: date)
    }
    
    private func formatScore(_ score: Double) -> String {
        return score.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", score) : String(format: "%.2f", score)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 涨幅汇总卡片
                    VStack(spacing: 8) {
                        Text("涨幅情况汇总")
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
                    
                    // 详细网格与独行备注展示
                    VStack(alignment: .leading, spacing: 12) {
                        Text("详细明细与备注").font(.headline).padding(.horizontal)
                        
                        ForEach(Array(record.rows.enumerated()), id: \.offset) { index, row in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("截止日期: \(formatDateMMdd(row.rowDate))")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Text("分值: \(formatScore(row.score))")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                
                                // 5 交易日网格
                                HStack(spacing: 4) {
                                    ForEach(0..<5, id: \.self) { col in
                                        let status = col < row.grid.count ? row.grid[col] : .smallUp
                                        Text(status.rawValue)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, minHeight: 30)
                                            .background(status.color)
                                            .cornerRadius(5)
                                    }
                                }
                                
                                // 备注单独占据独立一行，避免挤压
                                if !row.rowRemark.isEmpty {
                                    HStack(alignment: .top) {
                                        Image(systemName: "square.and.pencil")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                        Text("备注：\(row.rowRemark)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.orange.opacity(0.08))
                                    .cornerRadius(6)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
                        }
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("晴雨板详情 (\(record.recordKey))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}
