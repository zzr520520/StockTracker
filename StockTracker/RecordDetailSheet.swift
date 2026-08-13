import SwiftUI

struct RecordDetailSheet: View {
    @ObservedObject var storage = StorageManager.shared
    let recordKey: String
    @Environment(\.dismiss) var dismiss
    
    @State private var currentRecord: DailyRecord = DailyRecord(recordKey: "", rows: [])
    
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
                    // 涨跌汇总统计
                    VStack(spacing: 8) {
                        Text("涨跌汇总统计 (共8行/2个月)")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        HStack {
                            VStack {
                                Text("大涨").font(.caption).foregroundColor(.gray)
                                Text("\(currentRecord.bigUpCount)").font(.title3).bold().foregroundColor(GridStatus.bigUp.color)
                            }.frame(maxWidth: .infinity)
                            
                            VStack {
                                Text("小涨").font(.caption).foregroundColor(.gray)
                                Text("\(currentRecord.smallUpCount)").font(.title3).bold().foregroundColor(GridStatus.smallUp.color)
                            }.frame(maxWidth: .infinity)
                            
                            VStack {
                                Text("大跌").font(.caption).foregroundColor(.gray)
                                Text("\(currentRecord.bigDownCount)").font(.title3).bold().foregroundColor(GridStatus.bigDown.color)
                            }.frame(maxWidth: .infinity)
                            
                            VStack {
                                Text("小跌").font(.caption).foregroundColor(.gray)
                                Text("\(currentRecord.smallDownCount)").font(.title3).bold().foregroundColor(GridStatus.smallDown.color)
                            }.frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    
                    // 详细列表展示与可编辑备注
                    VStack(alignment: .leading, spacing: 14) {
                        Text("明细与备注修改").font(.headline).padding(.horizontal)
                        
                        ForEach(0..<currentRecord.rows.count, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("第 \(index + 1) 行 (日期: \(formatDateRange(start: currentRecord.rows[index].startDate, end: currentRecord.rows[index].endDate)))")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Text("分值: \(formatScore(currentRecord.rows[index].score))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                // 涨跌格子
                                HStack(spacing: 4) {
                                    ForEach(0..<5, id: \.self) { col in
                                        let status = col < currentRecord.rows[index].grid.count ? currentRecord.rows[index].grid[col] : .smallUp
                                        Text(status.rawValue)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, minHeight: 30)
                                            .background(status.color)
                                            .cornerRadius(6)
                                    }
                                }
                                
                                // 实时修改备注权限
                                HStack {
                                    Image(systemName: "pencil")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    TextField("在此处修改编辑本行备注...", text: $currentRecord.rows[index].rowRemark)
                                        .font(.system(size: 12))
                                        .textFieldStyle(.roundedBorder)
                                        .onChange(of: currentRecord.rows[index].rowRemark) { _ in
                                            storage.saveRecord(currentRecord)
                                        }
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
            .navigationTitle("晴雨板明细 (\(recordKey))")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let rec = storage.records[recordKey] {
                    self.currentRecord = rec
                } else {
                    self.currentRecord = DailyRecord(recordKey: recordKey, rows: (1...8).map { _ in DailyGridRow() })
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
