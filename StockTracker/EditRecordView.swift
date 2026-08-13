import SwiftUI

struct EditRecordView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var year: Int = Calendar.current.component(.year, from: Date())
    @State private var month: Int = Calendar.current.component(.month, from: Date())
    @State private var showMonthPicker = false
    @State private var rows: [DailyGridRow] = []
    @State private var alertMsg = ""
    @State private var showAlert = false
    @FocusState private var isInputActive: Bool
    
    private let weekLabels = ["第一周", "第二周", "第三周", "第四周"]
    
    var currentStorageKey: String {
        String(format: "%04d-%02d", year, month)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 1. 顶部年月（只选年月，绝对不带日）
                HStack {
                    Text("选择月份：").font(.subheadline).foregroundColor(.gray)
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
                
                // 2. 独立白底卡片风格的新增数据列表
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(0..<rows.count, id: \.self) { index in
                            let label = weekLabels[index]
                            
                            // 单周独立白底卡片
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("【\(label)】")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                    
                                    // 日期选择 + 自动设为 +4 天
                                    DatePicker("", selection: $rows[index].startDate, displayedComponents: .date)
                                        .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                                        .labelsHidden()
                                        .scaleEffect(0.85)
                                        .onChange(of: rows[index].startDate) { newStart in
                                            if let autoEnd = Calendar.current.date(byAdding: .day, value: 4, to: newStart) {
                                                rows[index].endDate = autoEnd
                                            }
                                        }
                                    
                                    Text("━")
                                        .font(.caption)
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
                                
                                // 格子美化，隔开
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
                                
                                // 备注与独立按钮
                                HStack {
                                    TextField("输入本周备注...", text: $rows[index].rowRemark)
                                        .font(.system(size: 12))
                                        .textFieldStyle(.roundedBorder)
                                        .focused($isInputActive)
                                    
                                    Button(action: { resetSingleRow(index: index) }) {
                                        Text("重置")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.red.opacity(0.1))
                                            .cornerRadius(6)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Button(action: { saveSingleRow(index: index) }) {
                                        Text("保存")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.blue)
                                            .cornerRadius(6)
                                    }
                                    .buttonStyle(PlainButtonStyle())
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
            }
            .navigationTitle("新增数据")
            .sheet(isPresented: $showMonthPicker) {
                MonthPickerView(selectedYear: $year, selectedMonth: $month)
                    .onDisappear { updateRowsForSelectedMonth() }
            }
            .onAppear(perform: updateRowsForSelectedMonth)
            .alert(alertMsg, isPresented: $showAlert) {
                Button("确定", role: .cancel) { }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") { isInputActive = false }.fontWeight(.bold)
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
    
    private func updateRowsForSelectedMonth() {
        if let existing = storage.records[currentStorageKey] {
            self.rows = existing.rows
        } else {
            let cal = Calendar.current
            var comp = DateComponents()
            comp.year = year
            comp.month = month
            comp.day = 1
            let firstDay = cal.date(from: comp) ?? Date()
            
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
        storage.resetSingleRow(recordKey: currentStorageKey, rowIndex: index)
        alertMsg = "【\(weekLabels[index])】已重置！"
        showAlert = true
    }
}
