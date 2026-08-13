import SwiftUI

struct EditRecordView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var mainDate = Date() // 顶部年月
    @State private var rows: [DailyGridRow] = (1...8).map { _ in DailyGridRow() }
    @State private var alertMsg = ""
    @State private var showAlert = false
    @FocusState private var isInputActive: Bool
    
    // 格式: yyyy-MM (年月)
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
                    // 1. 顶部年月选择（调动自动联动换月）
                    Section(header: Text("选择录入年月 (固定8行/2个月)")) {
                        HStack {
                            Text("年月：")
                            DatePicker("", selection: $mainDate, displayedComponents: [.date])
                                .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                                .labelsHidden()
                                .onChange(of: mainDate) { _ in
                                    // 自动调整联动月份并读取数据
                                    loadExistingData()
                                }
                            Spacer()
                            Text(currentStorageKey)
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // 2. 8 行录入（每行独立保存/重置，日期中间加横线 -）
                    Section(header: Text("每行单独控制保存与重置")) {
                        ForEach(0..<rows.count, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 8) {
                                // 第一行：日期区间 (加横线 - ) + 分值
                                HStack {
                                    Text("第 \(index + 1) 行:")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(index < 4 ? .blue : .purple)
                                    
                                    DatePicker("", selection: $rows[index].startDate, displayedComponents: .date)
                                        .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                                        .labelsHidden()
                                        .scaleEffect(0.85)
                                    
                                    // 中间加横线
                                    Text(" - ")
                                        .font(.subheadline)
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
                                
                                // 第二行：涨跌格子独立一行
                                HStack(spacing: 4) {
                                    ForEach(0..<5, id: \.self) { col in
                                        Button(action: {
                                            isInputActive = false
                                            toggleGridStatus(row: index, col: col)
                                        }) {
                                            Text(rows[index].grid[col].rawValue)
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity, minHeight: 30)
                                                .background(rows[index].grid[col].color)
                                                .cornerRadius(5)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                
                                // 第三行：备注独立一行 + 独立的保存与重置按钮
                                HStack {
                                    TextField("输入本行备注...", text: $rows[index].rowRemark)
                                        .font(.system(size: 12))
                                        .textFieldStyle(.roundedBorder)
                                        .focused($isInputActive)
                                    
                                    // 单行单独重置按钮
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
                                    
                                    // 单行单独保存按钮
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
            .onAppear(perform: loadExistingData)
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
    
    private func loadExistingData() {
        if let existing = storage.records[currentStorageKey] {
            self.rows = existing.rows
        } else {
            self.rows = (1...8).map { _ in DailyGridRow() }
        }
    }
    
    // 仅保存第 index 行的数据
    private func saveSingleRow(index: Int) {
        isInputActive = false
        storage.saveSingleRow(recordKey: currentStorageKey, rowIndex: index, rowData: rows[index])
        alertMsg = "第 \(index + 1) 行保存成功！"
        showAlert = true
    }
    
    // 仅重置第 index 行的数据
    private func resetSingleRow(index: Int) {
        isInputActive = false
        rows[index] = DailyGridRow()
        storage.saveSingleRow(recordKey: currentStorageKey, rowIndex: index, rowData: rows[index])
        alertMsg = "第 \(index + 1) 行已重置！"
        showAlert = true
    }
}
