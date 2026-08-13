import SwiftUI

struct DashboardView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var selectedDate = Date()
    @State private var showingDetailSheet = false
    
    var currentDateKey: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "yyyy-MM" // 顶部年-月
        return formatter.string(from: selectedDate)
    }
    
    var currentRecord: DailyRecord {
        storage.records[currentDateKey] ?? DailyRecord(
            recordKey: currentDateKey,
            rows: (1...6).map { _ in DailyGridRow() }
        )
    }
    
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
                
                // 网格展示（可点击整块查看备注）
                List {
                    Section(header: HStack {
                        Text("截止日").frame(width: 55, alignment: .leading)
                        HStack {
                            Text("周一").frame(maxWidth: .infinity)
                            Text("周二").frame(maxWidth: .infinity)
                            Text("周三").frame(maxWidth: .infinity)
                            Text("周四").frame(maxWidth: .infinity)
                            Text("周五").frame(maxWidth: .infinity)
                        }
                        Text("分值").frame(width: 35, alignment: .trailing)
                    }.font(.caption).foregroundColor(.gray)) {
                        ForEach(currentRecord.rows) { row in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(formatDateMMdd(row.rowDate))
                                        .font(.system(size: 11, weight: .bold))
                                        .frame(width: 55, alignment: .leading)
                                    
                                    HStack(spacing: 3) {
                                        ForEach(0..<5, id: \.self) { col in
                                            let status = col < row.grid.count ? row.grid[col] : .smallUp
                                            Text(status.rawValue)
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity, minHeight: 30)
                                                .background(status.color)
                                                .cornerRadius(5)
                                        }
                                    }
                                    
                                    Text(formatScore(row.score))
                                        .font(.system(.caption, design: .monospaced))
                                        .fontWeight(.semibold)
                                        .frame(width: 35, alignment: .trailing)
                                }
                                
                                // 若有备注，显示简短提示
                                if !row.rowRemark.isEmpty {
                                    Text("备注: \(row.rowRemark)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.orange)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 2)
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
                    
                    Button("查看完整晴雨板与备注详情") {
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
            .withFloatingTHSButton()
        }
    }
}
