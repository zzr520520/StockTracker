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
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: mainDate)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Form {
                    Section(header: HStack {
                        Text("主日期：")
                        DatePicker("", selection: $mainDate, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                            .labelsHidden()
                            .onChange(of: mainDate) { _ in loadExistingData() }
                    }) {
                        EmptyView()
                    }
                    
                    Section(header: HStack {
                        Text("左侧: 日期/备注").frame(width: 100, alignment: .leading)
                        Text("周一~周五 网格").frame(maxWidth: .infinity)
                        Text("分值").frame(width: 40, alignment: .trailing)
                    }.font(.caption)) {
                        ForEach(0..<rows.count, id: \.self) { index in
                            HStack(spacing: 6) {
                                // 所有功能/控制全部置于最左侧
                                VStack(alignment: .leading, spacing: 4) {
                                    DatePicker("", selection: $rows[index].rowDate, displayedComponents: .date)
                                        .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                                        .labelsHidden()
                                        .scaleEffect(0.85)
                                        .frame(width: 90, height: 24, alignment: .leading)
                                    
                                    TextField("备注...", text: $rows[index].rowRemark)
                                        .font(.system(size: 11))
                                        .textFieldStyle(.plain)
                                        .padding(2)
                                        .background(Color(UIColor.tertiarySystemFill))
                                        .cornerRadius(4)
                                        .focused($isInputActive)
                                }
                                .frame(width: 95)
                                
                                // 中间：5 交易日点击网格
                                HStack(spacing: 3) {
                                    ForEach(0..<5, id: \.self) { col in
                                        Button(action: {
                                            isInputActive = false
                                            toggleGridStatus(row: index, col: col)
                                        }) {
                                            Text(rows[index].grid[col].rawValue)
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity, minHeight: 34)
                                                .background(rows[index].grid[col].color)
                                                .cornerRadius(5)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                
                                // 右侧：分值输入
                                TextField("分值", value: $rows[index].score, format: .number)
                                    .keyboardType(.decimalPad)
                                    .focused($isInputActive)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 40, height: 34)
                                    .background(Color(UIColor.tertiarySystemFill))
                                    .cornerRadius(5)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                // 底部实体保存/重置按钮
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
            .withFloatingTHSButton()
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
