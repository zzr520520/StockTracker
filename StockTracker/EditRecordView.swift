import SwiftUI

struct EditRecordView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var mainDate = Date()
    @State private var rows: [DailyGridRow] = []
    @State private var alertMsg = ""
    @State private var showAlert = false
    @FocusState private var isInputActive: Bool
    
    private let weekLabels = ["第一周", "第二周", "第三周", "第四周"]
    
    // 仅显示年月格式 (如 2026年 09月)
    var currentYearMonthString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "yyyy年 MM月"
        return formatter.string(from: mainDate)
    }
    
    var currentStorageKey: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: mainDate)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Form {
                    // 1. 顶部年月选择 (仅显示年和月，切换自动更新下属所有周)
                    Section(header: Text("选择年月 (自动联动当月日期与数据)")) {
                        HStack {
                            Text("月份：")
                            DatePicker("", selection: $mainDate, displayedComponents: [.date])
                                .datePickerStyle(.compact)
                                .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                                .labelsHidden()
                                .onChange(of: mainDate) { _ in
                                    updateRowsForSelectedMonth()
                                }
                            Spacer()
                            Text(currentYearMonthString)
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // 2. 4周数据录入（美观横线、隔开格子、单行保存重置）
                    Section(header: Text("周数据录入（5天跨度自动校准）")) {
                        ForEach(0..<rows.count, id: \.self) { index in
                            let label = index < weekLabels.count ? weekLabels[index] : "第\(index+1)周"
                            
                            VStack(alignment: .leading, spacing: 8) {
                                // 第一行：周标签 + 起止日期 (加美观横线 ━ ) + 分值
                                HStack {
                                    Text("【\(label)】")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                    
                                    // 起始日期：修改后自动将截止日期设为 +4 天 (共5天)
                                    DatePicker("", selection: $rows[index].startDate, displayedComponents: .date)
                                        .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                                        .labelsHidden()
                                        .scaleEffect(0.85)
                                        .onChange(of: rows[index].startDate) { newStart in
                                            if let autoEnd = Calendar.current.date(byAdding: .day, value: 4, to: newStart) {
                                                rows[index].endDate = autoEnd
                                            }
                                        }
                                    
                                    // 美观分隔横杠
                                    Text("━")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.gray)
                                    
                                    DatePicker("", selection: $rows[index].endDate, displayedComponents: .date)
                                        .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                                        .labelsHidden()
                                        .scaleEffect(0.85)
                                    
                                    Spacer()
                                    
                                    TextField("分值", value: $rows[index].score, format: .number)
                                        .keyboardType(.decimalPad)
                                        .focused($isInputActive)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 45, height: 28)
                                        .background(Color(UIColor.tertiarySystemFill))
                                        .cornerRadius(5)
                                }
                                
                                // 第二行：涨跌格子（增加间距 spacing: 6，更美观隔开）
                                HStack(spacing: 6) {
                                    ForEach(0..<5, id: \.self) { col in
                                        Button(action: {
                                            isInputActive = false
                                            toggleGridStatus(row: index, col: col)
                                        }) {
                                            Text(rows[index].grid[col].rawValue)
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity, minHeight: 32)
                                                .background(rows[index].grid[col].color)
                                                .cornerRadius(6)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                
                                // 第三行：备注 + 独立重置/保存按钮
                                HStack {
                                    TextField("输入本周备注...", text: $rows[index].rowRemark)
                                        .font(.system(size: 12))
                                        .textFieldStyle(.roundedBorder)
                                        .focused($isInputActive)
                                    
                                    Button(action: { resetSingleRow(index: index) }) {
                                        Text("重置")
                                            .font(.caption2)
                                            .foregroundColor(.red)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 5)
                                            .background(Color.red.opacity(0.1))
                                            .cornerRadius(5)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Button(action: { saveSingleRow(index: index) }) {
                                        Text("保存")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 5)
                                            .background(Color.blue)
                                            .cornerRadius(5)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
            .navigationTitle("新增数据")
            .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
            .onAppear(perform: updateRowsForSelectedMonth)
            .alert(alertMsg, isPresented: $showAlert) {
                Button("确定", role: .cancel) { }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") { isInputActive = false }
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    private func toggleGridStatus(row: Int, col: Int) {
        let current = rows[row].grid[col]
        switch current {
        case .bigUp: rows[row].grid[col] = .smallUp
        case .smallUp: rows[row].grid[col] = .smallDown
        case .smallDown: rows[row].grid[col] = .bigDown
        case .bigDown: rows[row].grid[col] = .bigUp
        }
    }
    
    // 切换月份后，自动更替下属所有周的默认日期（5天一跨度）
    private func updateRowsForSelectedMonth() {
        if let existing = storage.records[currentStorageKey] {
            self.rows = existing.rows
        } else {
            let cal = Calendar.current
            let comp = cal.dateComponents([.year, .month], from: mainDate)
            let firstDay = cal.date(from: comp) ?? mainDate
            
            var newRows: [DailyGridRow] = []
            for i in 0..<4 {
                if let start = cal.date(byAdding: .day, value: i * 7, to: firstDay),
                   let end = cal.date(byAdding: .day, value: 4, to: start) {
                    newRows.append(DailyGridRow(startDate: start, endDate: end))
                }
            }
            self.rows = newRows
        }
    }
    
    private func saveSingleRow(index: Int) {
        isInputActive = false
        storage.saveSingleRow(recordKey: currentStorageKey, rowIndex: index, rowData: rows[index])
        alertMsg = "【\(weekLabels[index])】保存成功！"
        showAlert = true
    }
    
    private func resetSingleRow(index: Int) {
        isInputActive = false
        rows[index] = DailyGridRow()
        storage.saveSingleRow(recordKey: currentStorageKey, rowIndex: index, rowData: rows[index])
        alertMsg = "【\(weekLabels[index])】已重置！"
        showAlert = true
    }
}
