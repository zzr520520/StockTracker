import SwiftUI

struct EditRecordView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var mainDate = Date()
    @State private var rows: [DailyGridRow] = (1...6).map { _ in DailyGridRow() }
    @State private var showSaveAlert = false
    @FocusState private var isInputActive: Bool
    
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
                    Section(header: Text("选择录入年月")) {
                        HStack {
                            Text("年月：")
                            DatePicker("", selection: $mainDate, displayedComponents: [.date])
                                .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                                .labelsHidden()
                                .onChange(of: mainDate) { _ in loadExistingData() }
                            Spacer()
                            Text(currentStorageKey)
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Section(header: Text("每日数据录入（日期/格子/备注 分行隔离）")) {
                        ForEach(0..<rows.count, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 8) {
                                // 第一行：自定义日期范围 (如 8月3日 - 8月6日) + 分值
                                HStack {
                                    Text("起止:")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    DatePicker("", selection: $rows[index].startDate, displayedComponents: .date)
                                        .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                                        .labelsHidden()
                                        .scaleEffect(0.85)
                                    
                                    Text("-").font(.caption).foregroundColor(.gray)
                                    
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
                                
                                // 第二行：涨幅格子单独占据一行
                                HStack(spacing: 4) {
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
                                
                                // 第三行：备注单独占据一行
                                TextField("输入该条目备注...", text: $rows[index].rowRemark)
                                    .font(.system(size: 12))
                                    .textFieldStyle(.roundedBorder)
                                    .focused($isInputActive)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
                
                // 底部保存/清空按钮
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
            .onAppear(perform: loadExistingData)
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
    
    private func loadExistingData() {
        if let existing = storage.records[currentStorageKey] {
            self.rows = existing.rows
        } else {
            self.rows = (1...6).map { _ in DailyGridRow() }
        }
    }
    
    private func saveCurrentData() {
        isInputActive = false
        let record = DailyRecord(recordKey: currentStorageKey, rows: rows)
        storage.saveRecord(record)
        showSaveAlert = true
    }
    
    private func resetForm() {
        isInputActive = false
        self.rows = (1...6).map { _ in DailyGridRow() }
    }
}
