import SwiftUI

// 搜索结果项
struct SearchResultItem: Identifiable {
    var id: String { "\(recordKey)_\(weekLabel)" }
    let recordKey: String
    let weekLabel: String
    let row: DailyGridRow
}

// 备注编辑 Sheet 的目标
struct RemarkEditTarget: Identifiable {
    var id: String { "\(recordKey)_\(rowIndex)" }
    let recordKey: String
    let rowIndex: Int
    let weekLabel: String
}

struct DashboardView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var year: Int = Calendar.current.component(.year, from: Date())
    @State private var month: Int = Calendar.current.component(.month, from: Date())
    @State private var showMonthPicker = false
    @State private var showDetailSheet = false
    @State private var searchText = ""
    @State private var showSettings = false
    @State private var remarkEditTarget: RemarkEditTarget? = nil
    @State private var editingRemark = ""
    
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
    
    // 搜索匹配的结果（搜索所有日期和备注信息）
    private var searchResults: [SearchResultItem] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        var results: [SearchResultItem] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for (key, record) in storage.records.sorted(by: { $0.key > $1.key }) {
            for (index, row) in record.rows.enumerated() {
                guard row.isSet else { continue }
                let weekLabel = index < weekLabels.count ? weekLabels[index] : "第\(index + 1)周"
                let dateRangeStr = formatDateRange(start: row.startDate, end: row.endDate)
                let fullDateStr = dateFormatter.string(from: row.startDate)
                // 搜索范围：月份键 + 日期范围 + 完整日期 + 备注
                let searchableText = "\(key) \(dateRangeStr) \(fullDateStr) \(row.rowRemark)"
                
                if searchableText.lowercased().contains(query) {
                    results.append(SearchResultItem(recordKey: key, weekLabel: weekLabel, row: row))
                }
            }
        }
        return results
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 1. 顶部搜索栏 + 左上角设置按钮（搜索栏在晴雨板最顶部）
                HStack(spacing: 10) {
                    // 左上角设置按钮
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                    
                    // 搜索栏
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                        TextField("搜索日期或备注...", text: $searchText)
                            .font(.system(size: 14))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color(UIColor.tertiarySystemFill))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(UIColor.systemBackground))
                
                if searchText.isEmpty {
                    // --- 正常模式 ---
                    
                    // 2. 月份切换
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
                    
                    // 3. 晴雨板内容区
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
                                        // 未设置数据的空白占位格
                                        HStack(spacing: 6) {
                                            ForEach(0..<5, id: \.self) { _ in
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(Color(UIColor.tertiarySystemFill))
                                                    .frame(maxWidth: .infinity, minHeight: 32)
                                                    .overlay(Text("-").foregroundColor(.gray))
                                            }
                                        }
                                    }
                                    
                                    // 点击修改备注提示
                                    HStack {
                                        Spacer()
                                        Text("点击修改备注")
                                            .font(.system(size: 10))
                                            .foregroundColor(.blue.opacity(0.6))
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                                // 点击卡片修改备注
                                .onTapGesture {
                                    editingRemark = rowData?.rowRemark ?? ""
                                    remarkEditTarget = RemarkEditTarget(
                                        recordKey: currentDateKey,
                                        rowIndex: index,
                                        weekLabel: label
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                    .background(Color(UIColor.systemGroupedBackground))
                    
                    // 4. 底部统计栏
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
                    
                } else {
                    // --- 搜索模式 ---
                    ScrollView {
                        if searchResults.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("未找到相关记录")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
                            VStack(spacing: 12) {
                                Text("找到 \(searchResults.count) 条记录")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                ForEach(searchResults) { item in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(item.recordKey)
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .foregroundColor(.blue)
                                            
                                            Text("【\(item.weekLabel)】")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.blue)
                                            
                                            Spacer()
                                            
                                            Text(formatDateRange(start: item.row.startDate, end: item.row.endDate))
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            
                                            Text("分值: \(formatScore(item.row.score))")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                        }
                                        
                                        HStack(spacing: 6) {
                                            ForEach(0..<5, id: \.self) { col in
                                                let status = col < item.row.grid.count ? item.row.grid[col] : .smallUp
                                                Text(status.rawValue)
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .frame(maxWidth: .infinity, minHeight: 32)
                                                    .background(status.color)
                                                    .cornerRadius(6)
                                            }
                                        }
                                        
                                        if !item.row.rowRemark.isEmpty {
                                            Text("备注: \(item.row.rowRemark)")
                                                .font(.caption)
                                                .foregroundColor(.orange)
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
                    }
                    .background(Color(UIColor.systemGroupedBackground))
                }
            }
            .navigationTitle("晴雨板")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showMonthPicker) {
                MonthPickerView(selectedYear: $year, selectedMonth: $month)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            // 备注编辑 Sheet
            .sheet(item: $remarkEditTarget) { target in
                RemarkEditSheet(
                    weekLabel: target.weekLabel,
                    remark: $editingRemark,
                    onSave: {
                        storage.updateRemark(recordKey: target.recordKey, rowIndex: target.rowIndex, remark: editingRemark)
                        remarkEditTarget = nil
                    },
                    onCancel: {
                        remarkEditTarget = nil
                    }
                )
            }
        }
    }
}

// 备注编辑 Sheet
struct RemarkEditSheet: View {
    let weekLabel: String
    @Binding var remark: String
    let onSave: () -> Void
    let onCancel: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("修改【\(weekLabel)】备注")
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                TextField("请输入备注内容...", text: $remark, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                    .lineLimit(3...6)
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("编辑备注")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { onCancel() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { onSave() }
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isFocused = true
                }
            }
        }
    }
}
