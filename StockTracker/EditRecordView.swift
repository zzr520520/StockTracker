import SwiftUI

struct EditRecordView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var selectedDate = Date()
    @State private var tagNoteText: String = "" // 两侧右侧的标注
    @State private var rows: [DailyGridRow] = (1...6).map { _ in DailyGridRow() }
    @State private var showSaveAlert = false
    @FocusState private var isInputActive: Bool
    
    // 格式化日期，并自动校准/跳过周六日
    var currentDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }
    
    var currentStorageKey: String {
        let tag = tagNoteText.isEmpty ? "DEFAULT" : tagNoteText
        return "\(currentDateString)_\(tag)"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Form {
                    // 1. 顶部 Header：两侧分别为日期和标注
                    Section(header: Text("录入配置")) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("选择日期")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                    .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                                    .labelsHidden()
                                    .onChange(of: selectedDate) { newDate in
                                        adjustIfWeekend(date: newDate)
                                        loadExistingData()
                                    }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("股票/策略标注")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                TextField("例: 腾讯/大盘", text: $tagNoteText)
                                    .multilineTextAlignment(.trailing)
                                    .focused($isInputActive)
                                    .frame(width: 130)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: tagNoteText) { _ in loadExistingData() }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // 2. 网格区域（5列对齐周一至周五交易日）
                    Section(header: HStack {
                        Text("点击切换：大涨/小涨/小跌/大跌").font(.caption)
                        Spacer()
                        Text("周一  周二  周三  周四  周五").font(.caption2).foregroundColor(.blue)
                    }) {
                        ForEach(0..<rows.count, id: \.self) { rowIndex in
                            HStack {
                                Text("\(rowIndex + 1)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .frame(width: 20, alignment: .leading)
                                
                                // 5 天交易日网格
                                HStack(spacing: 4) {
                                    ForEach(0..<5, id: \.self) { colIndex in
                                        Button(action: {
                                            isInputActive = false
                                            toggleGridStatus(row: rowIndex, col: colIndex)
                                        }) {
                                            Text(rows[rowIndex].grid[colIndex].rawValue)
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity, minHeight: 34)
                                                .background(rows[rowIndex].grid[colIndex].color)
                                                .cornerRadius(6)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                
                                TextField("分值", value: $rows[rowIndex].score, format: .number)
                                    .keyboardType(.decimalPad)
                                    .focused($isInputActive)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 45, height: 34)
                                    .background(Color(UIColor.tertiarySystemFill))
                                    .cornerRadius(6)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                
                // 3. 底部实体操作按钮
                VStack(spacing: 10) {
                    HStack(spacing: 15) {
                        Button(action: resetForm) {
                            HStack {
                                Image(systemName: "trash")
                                Text("重置清除")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Color.red.opacity(0.12))
                            .cornerRadius(10)
                        }
                        
                        Button(action: saveCurrentData) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("保存记录")
                            }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
                .background(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -2)
            }
            .navigationTitle("新增数据")
            .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
            .onAppear {
                adjustIfWeekend(date: selectedDate)
                loadExistingData()
            }
            .alert("保存成功", isPresented: $showSaveAlert) {
                Button("确定", role: .cancel) { }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") { isInputActive = false }
                        .fontWeight(.bold)
                }
            }
            .withFloatingTHSButton()
        }
    }
    
    // 循环切换一大一小（大涨 -> 小涨 -> 小跌 -> 大跌）
    private func toggleGridStatus(row: Int, col: Int) {
        let current = rows[row].grid[col]
        switch current {
        case .bigUp: rows[row].grid[col] = .smallUp
        case .smallUp: rows[row].grid[col] = .smallDown
        case .smallDown: rows[row].grid[col] = .bigDown
        case .bigDown: rows[row].grid[col] = .bigUp
        }
    }
    
    // 自动跳过周六和周日
    private func adjustIfWeekend(date: Date) {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        if weekday == 7 { // 周六 -> 自动切到周五
            if let adjusted = calendar.date(byAdding: .day, value: -1, to: date) {
                selectedDate = adjusted
            }
        } else if weekday == 1 { // 周日 -> 自动切到下周一
            if let adjusted = calendar.date(byAdding: .day, value: 1, to: date) {
                selectedDate = adjusted
            }
        }
    }
    
    private func loadExistingData() {
        if let existing = storage.records[currentStorageKey] {
            self.rows = existing.rows
        } else {
            self.rows = (1...6).map { _ in DailyGridRow() }
        }
    }
    
    private func saveCurrentData() {
        isInputActive = false
        let record = DailyRecord(
            dateString: currentDateString,
            tagNote: tagNoteText,
            rows: rows
        )
        storage.saveRecord(record)
        showSaveAlert = true
    }
    
    private func resetForm() {
        isInputActive = false
        self.rows = (1...6).map { _ in DailyGridRow() }
    }
}
