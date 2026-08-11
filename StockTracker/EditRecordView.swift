import SwiftUI

struct EditRecordView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var selectedDate = Date()
    @State private var rows: [DailyGridRow] = (1...8).map { _ in DailyGridRow() }
    @State private var showSaveAlert = false
    @FocusState private var isInputActive: Bool // 焦点控制
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
    
    var currentDateString: String {
        dateFormatter.string(from: selectedDate)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("选择日期")) {
                    DatePicker("日期", selection: $selectedDate, displayedComponents: .date)
                        .onChange(of: selectedDate) { _ in
                            loadExistingData()
                        }
                }
                
                Section(header: Text("点击网格可快速切换 涨 / 跌")) {
                    ForEach(0..<rows.count, id: \.self) { rowIndex in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("第 \(rowIndex + 1) 行")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            HStack {
                                HStack(spacing: 6) {
                                    ForEach(0..<5, id: \.self) { colIndex in
                                        Button(action: {
                                            rows[rowIndex].grid[colIndex] = (rows[rowIndex].grid[colIndex] == .up) ? .down : .up
                                        }) {
                                            Text(rows[rowIndex].grid[colIndex].rawValue)
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity, minHeight: 36)
                                                .background(rows[rowIndex].grid[colIndex] == .up ? Color.red : Color.green)
                                                .cornerRadius(6)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                
                                Spacer()
                                
                                TextField("分值", value: $rows[rowIndex].score, format: .number)
                                    .keyboardType(.numberPad)
                                    .focused($isInputActive) // 绑定键盘焦点
                                    .multilineTextAlignment(.center)
                                    .frame(width: 50, height: 36)
                                    .background(Color(UIColor.tertiarySystemFill))
                                    .cornerRadius(6)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section {
                    Button(action: saveCurrentData) {
                        HStack {
                            Spacer()
                            Text("保存记录").fontWeight(.bold).foregroundColor(.blue)
                            Spacer()
                        }
                    }
                    
                    Button(action: resetForm) {
                        HStack {
                            Spacer()
                            Text("重置清空").foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("数据录入")
            .onAppear(perform: loadExistingData)
            .alert("保存成功", isPresented: $showSaveAlert) {
                Button("确定", role: .cancel) { }
            }
            // 修复 1：添加顶部键盘工具栏，点击"完成"关闭键盘
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") {
                        isInputActive = false
                    }
                    .fontWeight(.bold)
                }
            }
            // 修复 2：点击非输入区域自动收起键盘
            .onTapGesture {
                isInputActive = false
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
