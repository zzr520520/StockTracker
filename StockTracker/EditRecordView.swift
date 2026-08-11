import SwiftUI

struct EditRecordView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var selectedDate = Date()
    @State private var rows: [DailyGridRow] = (1...8).map { _ in DailyGridRow() }
    @State private var showSaveAlert = false
    
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
                        .onChange(of: selectedDate) { newDate in
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
                                // 5列可点击网格
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
                                
                                // 分值输入
                                TextField("分值", value: $rows[rowIndex].score, format: .number)
                                    .keyboardType(.numberPad)
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
        let record = DailyRecord(dateString: currentDateString, rows: rows)
        storage.saveRecord(record)
        showSaveAlert = true
    }
    
    private func resetForm() {
        self.rows = (1...8).map { _ in DailyGridRow() }
    }
}
