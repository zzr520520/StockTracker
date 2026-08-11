import SwiftUI

struct EditRecordView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var selectedDate = Date()
    @State private var rows: [DailyGridRow] = (1...8).map { _ in DailyGridRow() }
    @State private var showSaveAlert = false
    @FocusState private var isInputActive: Bool
    
    // 1. 存储给数据库用的日期 Key (yyyy-MM-dd)
    var currentDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN") // 强制中文 Locale
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }
    
    // 2. 界面上展示给用户看的中文字符串 (例：2026年08月11日)
    var chineseDisplayDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN") // 强制中文 Locale
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Form {
                    Section(header: Text("选择日期")) {
                        HStack {
                            Text("当前日期")
                            Spacer()
                            // 强制中文显示与中文日历控件
                            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                .labelsHidden()
                                .environment(\.locale, Locale(identifier: "zh_CN"))
                                .environment(\.calendar, Calendar(identifier: .gregorian))
                                .onChange(of: selectedDate) { _ in
                                    loadExistingData()
                                }
                        }
                    }
                    
                    Section(header: Text("点击网格可切换 涨 / 跌")) {
                        ForEach(0..<rows.count, id: \.self) { rowIndex in
                            HStack {
                                Text("第 \(rowIndex + 1) 行")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .frame(width: 50, alignment: .leading)
                                
                                HStack(spacing: 5) {
                                    ForEach(0..<5, id: \.self) { colIndex in
                                        Button(action: {
                                            isInputActive = false
                                            rows[rowIndex].grid[colIndex] = (rows[rowIndex].grid[colIndex] == .up) ? .down : .up
                                        }) {
                                            Text(rows[rowIndex].grid[colIndex].rawValue)
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity, minHeight: 32)
                                                .background(rows[rowIndex].grid[colIndex] == .up ? Color.red : Color.green)
                                                .cornerRadius(6)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                
                                Spacer()
                                
                                TextField("分值", value: $rows[rowIndex].score, format: .number)
                                    .keyboardType(.numberPad)
                                    .focused($isInputActive)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 45, height: 32)
                                    .background(Color(UIColor.tertiarySystemFill))
                                    .cornerRadius(6)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                
                // 底部两个独立高亮实体按钮
                VStack(spacing: 10) {
                    HStack(spacing: 15) {
                        Button(action: resetForm) {
                            HStack {
                                Image(systemName: "trash")
                                Text("重置清除")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, minHeight: 45)
                            .background(Color.red.opacity(0.12))
                            .cornerRadius(10)
                        }
                        
                        Button(action: saveCurrentData) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("保存记录")
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 45)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 15)
                }
                .background(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -2)
            }
            .navigationTitle("数据录入")
            .onAppear(perform: loadExistingData)
            .alert("保存成功", isPresented: $showSaveAlert) {
                Button("确定", role: .cancel) { }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") {
                        isInputActive = false
                    }
                    .fontWeight(.bold)
                }
            }
            .withFloatingTHSButton()
        }
    }
    
    private func loadExistingData() {
        if let existing = storage.records[currentDateString] {
            self.rows = existing.rows
        } else {
            self.rows = (1...8).map { _ in DailyGridRow() }
        }
    }
    
    private func saveCurrentData() {
        isInputActive = false
        let record = DailyRecord(dateString: currentDateString, rows: rows)
        storage.saveRecord(record)
        showSaveAlert = true
    }
    
    private func resetForm() {
        isInputActive = false
        self.rows = (1...8).map { _ in DailyGridRow() }
    }
}
