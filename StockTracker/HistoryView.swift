import SwiftUI

struct HistoryView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var searchText = ""
    @State private var selectedRecordForDetail: DailyRecord? = nil
    
    // Zip 导入/导出控制
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var exportZipDoc: ZipDocument? = nil
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    var filteredRecords: [DailyRecord] {
        let all = Array(storage.records.values).sorted { $0.recordKey > $1.recordKey }
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return all
        }
        var result: [DailyRecord] = []
        for record in all {
            let matchDate = record.recordKey.contains(trimmed)
            var matchRemark = false
            for row in record.rows {
                if row.rowRemark.contains(trimmed) {
                    matchRemark = true
                    break
                }
            }
            if matchDate || matchRemark {
                result.append(record)
            }
        }
        return result
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("备份与恢复操作")) {
                        HStack(spacing: 12) {
                            // 1. Zip 导出备份
                            Button(action: exportBackupZip) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("导出 Zip 备份文件")
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 38)
                                .background(Color.blue)
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // 2. Zip 导入恢复
                            Button(action: { showingImporter = true }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("导入 Zip 恢复")
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 38)
                                .background(Color.green)
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Section(header: Text("历史列表 (点击可查看详情与独立备注)")) {
                        ForEach(filteredRecords) { record in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(record.recordKey)
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Text("大涨:\(record.bigUpCount) 小涨:\(record.smallUpCount) 大跌:\(record.bigDownCount) 小跌:\(record.smallDownCount)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                
                                // 显示所有独立行的备注
                                let remarks = record.rows.map { $0.rowRemark }.filter { !$0.isEmpty }
                                if !remarks.isEmpty {
                                    VStack(alignment: .leading, spacing: 2) {
                                        ForEach(remarks, id: \.self) { rem in
                                            Text("• 备注: \(rem)")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                                .lineLimit(1)
                                        }
                                    }
                                    .padding(4)
                                    .background(Color.orange.opacity(0.08))
                                    .cornerRadius(4)
                                }
                                
                                // 网格缩略图
                                VStack(spacing: 2) {
                                    ForEach(record.rows.prefix(3)) { row in
                                        HStack(spacing: 3) {
                                            ForEach(0..<5, id: \.self) { col in
                                                let st = col < row.grid.count ? row.grid[col] : .smallUp
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(st.color)
                                                    .frame(height: 6)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedRecordForDetail = record
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let item = filteredRecords[index]
                                storage.deleteRecord(key: item.recordKey)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("历史记录")
            .searchable(text: $searchText, prompt: "搜索年月或备注内容...")
            .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
            .sheet(item: $selectedRecordForDetail) { record in
                RecordDetailSheet(record: record)
            }
            // 导出备份文档构建器
            .fileExporter(isPresented: $showingExporter, document: exportZipDoc, contentType: .zip, defaultFilename: "SunnyRain_Backup_\(Int(Date().timeIntervalSince1970)).zip") { result in
                switch result {
                case .success:
                    alertMessage = "导出 Zip 备份文件成功！"
                case .failure(let err):
                    alertMessage = "导出失败: \(err.localizedDescription)"
                }
                showAlert = true
            }
            // 导入备份文档选择器
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.zip, .archive, .json]) { result in
                switch result {
                case .success(let url):
                    if url.startAccessingSecurityScopedResource() {
                        defer { url.stopAccessingSecurityScopedResource() }
                        if let data = try? Data(contentsOf: url), storage.importBackupFromData(data) {
                            alertMessage = "导入并恢复 Zip 数据成功！"
                        } else {
                            alertMessage = "导入失败：格式不匹配或文件已损坏。"
                        }
                    }
                case .failure(let err):
                    alertMessage = "选择文件失败: \(err.localizedDescription)"
                }
                showAlert = true
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("确定", role: .cancel) { }
            }
            .withFloatingTHSButton()
        }
    }
    
    private func exportBackupZip() {
        if let zipData = storage.generateBackupZipData() {
            self.exportZipDoc = ZipDocument(data: zipData)
            self.showingExporter = true
        } else {
            alertMessage = "生成备份文件失败"
            showAlert = true
        }
    }
}
