import SwiftUI

struct DashboardView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var selectedDate = Date()
    @State private var selectedTagNote: String = ""
    
    var currentDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }
    
    var currentRecord: DailyRecord {
        let key = "\(currentDateString)_\(selectedTagNote.isEmpty ? "DEFAULT" : selectedTagNote)"
        return storage.records[key] ?? DailyRecord(
            dateString: currentDateString,
            tagNote: selectedTagNote,
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
    
    // 提取所有可用的标注（去重、过滤空值）
    var availableTagNotes: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for record in storage.records.values {
            let tag = record.tagNote
            if !tag.isEmpty && !seen.contains(tag) {
                seen.insert(tag)
                result.append(tag)
            }
        }
        return result
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 1. 顶部日期与标注切换 Header
                HStack {
                    DatePicker("日期", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                    
                    Spacer()
                    
                    // 动态显示当前可用的标注/标签
                    Menu {
                        Button("默认/通用") { selectedTagNote = "" }
                        ForEach(availableTagNotes, id: \.self) { tag in
                            Button(tag) { selectedTagNote = tag }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "tag.fill").font(.caption)
                            Text(selectedTagNote.isEmpty ? "默认看板" : selectedTagNote)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.12))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGroupedBackground))
                
                // 2. 5交易日（周一至周五）核心看板
                List {
                    Section(header: HStack {
                        Text("行").frame(width: 25, alignment: .leading)
                        HStack {
                            Text("周一").frame(maxWidth: .infinity)
                            Text("周二").frame(maxWidth: .infinity)
                            Text("周三").frame(maxWidth: .infinity)
                            Text("周四").frame(maxWidth: .infinity)
                            Text("周五").frame(maxWidth: .infinity)
                        }
                        Text("分值").frame(width: 45, alignment: .trailing)
                    }.font(.caption).foregroundColor(.gray)) {
                        ForEach(Array(currentRecord.rows.enumerated()), id: \.offset) { index, row in
                            HStack {
                                Text("\(index + 1)")
                                    .font(.system(.caption, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                    .frame(width: 25, alignment: .leading)
                                
                                HStack(spacing: 4) {
                                    ForEach(0..<5, id: \.self) { colIndex in
                                        let status = colIndex < row.grid.count ? row.grid[colIndex] : .smallUp
                                        Text(status.rawValue)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, minHeight: 32)
                                            .background(status.color)
                                            .cornerRadius(6)
                                    }
                                }
                                
                                Text(formatScore(row.score))
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.semibold)
                                    .frame(width: 45, alignment: .trailing)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                
                // 3. 底部统计（区分包含大/小的总涨跌）
                HStack {
                    HStack(spacing: 4) {
                        Text("周上涨和:")
                        Text("\(currentRecord.totalUpCount)")
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Text("周下跌和:")
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
