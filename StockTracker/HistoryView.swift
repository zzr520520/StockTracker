import SwiftUI
import UniformTypeIdentifiers

struct HistoryView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var searchText = ""
    @State private var selectedRecordForDetail: DailyRecord? = nil
    
    // 备份控制
    @State private var shareURL: URL? = nil
    @State private var showShareSheet = false
    @State private var showImporter = false
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
                    Section(header: Text("备份与恢复")) {
                        HStack(spacing: 12) {
                            // 1. 系统分享导出 Zip
                            Button(action: exportAndShareZip) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("分享导出 Zip 备份")
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 38)
                                .background(Color.blue)
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // 2. 导入 Zip 文件恢复
                            Button(action: { showImporter = true }) {
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
                    
                    Section(header: Text("历史列表 (点击任意卡片查看详情)")) {
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
            .sheet(isPresented: $showShareSheet) {
                if let url = shareURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.zip, .archive, .item]) { result in
                switch result {
                case .success(let url):
                    if storage.importFromURL(url) {
                        alertMessage = "恢复备份数据成功！"
                    } else {
                        alertMessage = "导入失败：格式不匹配或 Zip 文件无效。"
                    }
                case .failure(let err):
                    alertMessage = "读取文件失败: \(err.localizedDescription)"
                }
                showAlert = true
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("确定", role: .cancel) { }
            }
        }
    }
    
    private func exportAndShareZip() {
        if let url = storage.generateZipFileURL() {
            self.shareURL = url
            self.showShareSheet = true
        } else {
            alertMessage = "生成备份文件失败"
            showAlert = true
        }
    }
}
