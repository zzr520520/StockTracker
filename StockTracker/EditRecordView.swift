import SwiftUI

struct EditRecordView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var selectedDate = Date()
    @State private var selectedStockCode: String = ""
    @State private var remarkText: String = ""
    @State private var rows: [DailyGridRow] = (1...8).map { _ in DailyGridRow() }
    @State private var showSaveAlert = false
    @FocusState private var isInputActive: Bool
    
    var currentDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Form {
                    Section(header: Text("基本信息")) {
                        // 1. 日期选择
                        DatePicker("日期", selection: $selectedDate, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                            .onChange(of: selectedDate) { _ in
                                loadExistingData()
                            }
                        
                        // 2. 选择关联股票（自动同步自选股列表）
                        Picker("关联个股/大盘", selection: $selectedStockCode) {
                            Text("无 (通用/大盘)").tag("")
                            ForEach(storage.favoriteStocks) { stock in
                                Text("\(stock.name) (\(stock.code))").tag(stock.code)
                            }
                        }
                    }
                    
                    // 3. 备注功能
                    Section(header: Text("每日备注记录")) {
                        TextField("输入今日操作笔记、看盘心得等备注...", text: $remarkText)
                            .focused($isInputActive)
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
                                    .keyboardType(.decimalPad)
                                    .focused($isInputActive)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 55, height: 32)
                                    .background(Color(UIColor.tertiarySystemFill))
                                    .cornerRadius(6)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                
                // 底部操作按钮
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
            .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
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
            self.selectedStockCode = existing.stockCode
            self.remarkText = existing.remark
        } else {
            self.rows = (1...8).map { _ in DailyGridRow() }
            self.selectedStockCode = ""
            self.remarkText = ""
        }
    }
    
    private func saveCurrentData() {
        isInputActive = false
        let stockName = storage.favoriteStocks.first(where: { $0.code == selectedStockCode })?.name ?? ""
        let record = DailyRecord(
            dateString: currentDateString,
            stockCode: selectedStockCode,
            stockName: stockName,
            remark: remarkText,
            rows: rows
        )
        storage.saveRecord(record)
        showSaveAlert = true
    }
    
    private func resetForm() {
        isInputActive = false
        self.rows = (1...8).map { _ in DailyGridRow() }
        self.selectedStockCode = ""
        self.remarkText = ""
    }
}
